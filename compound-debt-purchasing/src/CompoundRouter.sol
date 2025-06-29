// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ICompoundDebt} from "./interfaces/ICompoundDebt.sol";
import {ICompoundRouter} from "./interfaces/ICompoundRouter.sol";
import {CometInterface} from "@comet/contracts/CometInterface.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

contract CompoundRouter is ICompoundRouter, AccessControl {
    using Clones for address;
    using SafeERC20 for IERC20;

    uint256 public constant ONE_HUNDRED_PERCENT = 10_000;

    address public immutable compoundDebtimplementation;
    mapping(address => uint256) public userNonces;
    mapping(address => address) public debtOwners;
    mapping(address => uint256) public debtNonces;
    mapping(address => bool) public verifiedComets;
    mapping(address => address) public debtComets;

    constructor(address _compoundDebtImplementation, address _admin) {
        compoundDebtimplementation = _compoundDebtImplementation;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function verifyComet(address _comet) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!verifiedComets[_comet], "Comet already verified");
        verifiedComets[_comet] = true;
        emit CometVerified(_comet);
    }

    function predictDebtAddress(address user) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(user, userNonces[user]));
        return
            Clones.predictDeterministicAddress(
                compoundDebtimplementation,
                salt
            );
    }

    function multicall(bytes[] calldata data) external {
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            require(success, _getRevertMsg(result));
        }
    }

    function createDebt(address _comet) external returns (address) {
        require(verifiedComets[_comet], "Comet not verified");
        bytes32 salt = keccak256(
            abi.encodePacked(msg.sender, userNonces[msg.sender])
        );
        address clone = Clones.cloneDeterministic(
            compoundDebtimplementation,
            salt
        );
        ICompoundDebt(clone).initialize(_comet);
        debtOwners[clone] = msg.sender;
        userNonces[msg.sender] += 1;
        debtComets[clone] = _comet;
        emit CreateDebt(_comet, clone, msg.sender);
        return clone;
    }

    function transferDebtOwnership(address debt, address newOwner) external {
        require(msg.sender == debtOwners[debt], "Not owner");
        debtOwners[debt] = newOwner;
        debtNonces[debt] += 1;

        emit TransferDebtOwnership(debt, newOwner);
    }

    function cancelDebtCurrentOrders(address debt) external {
        require(msg.sender == debtOwners[debt], "Not owner");
        debtNonces[debt] += 1;
        emit CancelCurrentDebtOrders(debt);
    }

    function callSupply(address debt, address asset, uint256 amount) external {
        address comet = debtComets[debt];
        CometInterface(comet).getAssetInfoByAddress(asset); // to check

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).safeApprove(address(comet), amount);

        CometInterface(comet).supplyTo(debt, asset, amount);

        emit Supply(debt, asset, amount);
    }

    function callSupplyWithPermit(
        address debt,
        address asset,
        uint256 amount,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external {
        IERC20Permit(asset).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            permitV,
            permitR,
            permitS
        );

        address comet = debtComets[debt];
        CometInterface(comet).getAssetInfoByAddress(asset); // to check

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).safeApprove(address(comet), amount);
        CometInterface(comet).supplyTo(debt, asset, amount);
        emit Supply(debt, asset, amount);
    }

    function callBorrow(
        address debt,
        address asset,
        uint256 amount,
        address to
    ) external {
        require(debtOwners[debt] == msg.sender, "Not owner");
        address comet = debtComets[debt];
        require(asset == CometInterface(comet).baseToken(), "Invalid asset");
        ICompoundDebt(debt).withdraw(asset, amount, to);
        emit Borrow(debt, asset, amount, to);
    }

    function callWithdraw(
        address debt,
        address asset,
        uint256 amount,
        address to
    ) external {
        require(debtOwners[debt] == msg.sender, "Not owner");
        address comet = debtComets[debt];
        CometInterface(comet).getAssetInfoByAddress(asset); // to check
        ICompoundDebt(debt).withdraw(asset, amount, to);
        emit Withdraw(debt, asset, amount, to);
    }

    function callRepay(address debt, address asset, uint256 amount) external {
        address comet = debtComets[debt];
        require(asset == CometInterface(comet).baseToken(), "Invalid asset");
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).safeApprove(address(comet), amount);

        CometInterface(comet).supplyTo(debt, asset, amount);
        emit Repay(debt, asset, amount);
    }

    function callRepayWithPermit(
        address debt,
        address asset,
        uint256 amount,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external {
        IERC20Permit(asset).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            permitV,
            permitR,
            permitS
        );

        address comet = debtComets[debt];
        require(asset == CometInterface(comet).baseToken(), "Invalid asset");
        CometInterface(comet).supplyTo(debt, asset, amount);
        emit Repay(debt, asset, amount);
    }

    function _getRevertMsg(
        bytes memory revertData
    ) internal pure returns (string memory) {
        if (revertData.length < 68) return "Multicall failed";
        assembly {
            revertData := add(revertData, 0x04)
        }
        return abi.decode(revertData, (string));
    }
}
