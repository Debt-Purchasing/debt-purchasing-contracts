// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPriceOracleGetter.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

import "./interfaces/IAaveDebt.sol";
import "./interfaces/IAaveRouter.sol";

contract AaveRouter is IAaveRouter {
    using SafeERC20 for IERC20;

    uint256 public constant ONE_HUNDRED_PERCENT = 10_000;

    address public immutable aaveDebtImplementation;
    mapping(address => uint256) public userNonces;
    mapping(address => address) public debtOwners;
    mapping(address => uint256) public debtNonces;

    IPoolAddressesProvider public aavePoolAddressesProvider;
    IPool public aavePool;
    IPriceOracleGetter public aaveOracle;

    constructor(
        address _aaveDebtImplementation,
        address _aavePoolAddressesProvider
    ) {
        aaveDebtImplementation = _aaveDebtImplementation;
        aavePoolAddressesProvider = IPoolAddressesProvider(
            _aavePoolAddressesProvider
        );
        aavePool = IPool(aavePoolAddressesProvider.getPool());
        aaveOracle = IPriceOracleGetter(
            aavePoolAddressesProvider.getPriceOracle()
        );
    }

    function predictDebtAddress(address user) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(user, userNonces[user]));
        return
            Clones.predictDeterministicAddress(
                aaveDebtImplementation,
                salt,
                address(this)
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

    function createDebt() external returns (address) {
        bytes32 salt = keccak256(
            abi.encodePacked(msg.sender, userNonces[msg.sender])
        );
        address clone = Clones.cloneDeterministic(aaveDebtImplementation, salt);
        IAaveDebt(clone).initialize(aavePool);
        debtOwners[clone] = msg.sender;
        userNonces[msg.sender]++;
        return clone;
    }

    function callSupply(address debt, address asset, uint256 amount) external {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(aavePool), amount);

        aavePool.supply(asset, amount, debt, 0);
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

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(aavePool), amount);

        aavePool.supply(asset, amount, debt, 0);
    }

    function callBorrow(
        address debt,
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external {
        require(debtOwners[debt] == msg.sender, "Not owner");
        IAaveDebt(debt).borrow(asset, amount, interestRateMode, onBehalfOf);
    }

    function callWithdraw(
        address debt,
        address asset,
        uint256 amount,
        address to
    ) external {
        require(debtOwners[debt] == msg.sender, "Not owner");
        IAaveDebt(debt).withdraw(asset, amount, to);
    }

    function transferDebtOwnership(address debt, address newOwner) external {
        require(msg.sender == debtOwners[debt], "Not owner");
        debtOwners[debt] = newOwner;
    }

    function callRepay(
        address debt,
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(aavePool), amount);
        aavePool.repay(asset, amount, interestRateMode, debt);
    }

    function callRepayWithPermit(
        address debt,
        address asset,
        uint256 amount,
        uint256 interestRateMode,
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
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(aavePool), amount);
        aavePool.repay(asset, amount, interestRateMode, debt);
    }

    function callRepayWithATokens(
        address debt,
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external {
        address aToken = aavePool.getReserveData(asset).aTokenAddress;

        IERC20(aToken).safeTransferFrom(msg.sender, debt, amount);

        IAaveDebt(debt).repayWithATokens(
            asset,
            amount,
            interestRateMode,
            msg.sender
        );
    }

    function callSwapBorrowRateMode(
        address debt,
        address asset,
        uint256 interestRateMode
    ) external {
        require(msg.sender == debtOwners[debt], "Not owner");
        IAaveDebt(debt).swapBorrowRateMode(asset, interestRateMode);
    }

    function executeFullSale(
        SellOrder calldata order,
        uint256 minProfit // based on base currency
    ) external {
        require(
            block.timestamp >= order.startTime &&
                block.timestamp <= order.endTime,
            "Order expired"
        );
        require(order.isFullSale, "Not fullSale");

        address debt = order.debt;
        address seller = debtOwners[debt];
        require(seller != address(0), "Invalid debt");
        require(order.debtNonce == debtNonces[debt], "Invalid debt nonce");

        // verify signature
        require(
            _verifySellOrder(order, seller, order.v, order.r, order.s),
            "Invalid signature"
        );

        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            ,
            ,
            ,
            uint256 hf
        ) = aavePool.getUserAccountData(debt);

        // check HF
        require(hf <= order.triggerHF, "HF too high");

        // calculate basePayValue based on fullSaleExtra
        uint256 basePayValue = (totalDebtBase * order.fullSaleExtra) /
            ONE_HUNDRED_PERCENT;

        // check profit
        require(
            totalCollateralBase - (totalDebtBase + basePayValue) >= minProfit,
            "Insufficient profit"
        );

        // convert totalDebtBase (in USD 1e8) to fullSaleToken amount
        uint256 fullSalePayValue = _getTokenValueFromUsd(
            basePayValue,
            order.fullSaleToken,
            aaveOracle.getAssetPrice(order.fullSaleToken),
            8
        );

        // transfer fullSalePayValue from buyer to seller
        IERC20(order.fullSaleToken).safeTransferFrom(
            msg.sender,
            seller,
            fullSalePayValue
        );

        // increase debt nonce to cancel all currentOrder
        debtNonces[debt] += 1;
        // transfer ownership of debt to buyer
        debtOwners[debt] = msg.sender;

        // emit FullSaleExecuted(msg.sender, seller, debt, fullSalePrice);
    }

    function _getTokenValueFromUsd(
        uint256 usdValue, // 18 decimals
        address token,
        uint256 price, // 8 decimals,
        uint8 priceDecimals
    ) public view returns (uint256) {
        uint8 tokenDecimals = IERC20Metadata(token).decimals();
        uint256 valueIn18 = (usdValue * (10 ** priceDecimals)) / price;

        if (tokenDecimals < 18) {
            return valueIn18 / (10 ** (18 - tokenDecimals));
        } else {
            return valueIn18 * (10 ** (tokenDecimals - 18));
        }
    }

    function _verifySellOrder(
        SellOrder calldata order,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {}

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
