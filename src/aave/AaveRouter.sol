// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPriceOracleGetter.sol";
import "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol";
import "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IAaveDebt.sol";
import "./interfaces/IAaveRouter.sol";

contract AaveRouter is IAaveRouter {
    using SafeERC20 for IERC20;

    uint256 public constant ONE_HUNDRED_PERCENT = 10_000;

    bytes32 public constant FULL_SELL_ORDER_TYPE_HASH =
        keccak256(
            "FullSellOrder(uint256 chainId,address contract,OrderTitle title,address fullSaleToken,uint256 fullSaleExtra)"
        );

    bytes32 public constant PARTIAL_SELL_ORDER_TYPE_HASH =
        keccak256(
            "PartialSellOrder(uint256 chainId,address contract,OrderTitle title,uint256 interestRateMode,address[] collateralOut,uint256[] percents,address repayToken,uint256 repayAmount,uint256 bonus)"
        );

    bytes32 public constant ORDER_TITLE_TYPE_HASH =
        keccak256(
            "OrderTitle(address debt,uint256 debtNonce,uint256 startTime,uint256 endTime,uint256 triggerHF)"
        );

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
        userNonces[msg.sender] += 1;
        emit CreateDebt(clone, msg.sender);
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
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(aavePool), amount);

        aavePool.supply(asset, amount, debt, 0);

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

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(aavePool), amount);

        aavePool.supply(asset, amount, debt, 0);
        emit Supply(debt, asset, amount);
    }

    function callBorrow(
        address debt,
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address receiver
    ) external {
        require(debtOwners[debt] == msg.sender, "Not owner");
        IAaveDebt(debt).borrow(asset, amount, interestRateMode, receiver);

        emit Borrow(debt, asset, amount, interestRateMode);
    }

    function callWithdraw(
        address debt,
        address asset,
        uint256 amount,
        address to
    ) external {
        require(debtOwners[debt] == msg.sender, "Not owner");
        IAaveDebt(debt).withdraw(asset, amount, to);
        emit Withdraw(debt, asset, amount, to);
    }

    function callRepay(
        address debt,
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        // Always do a two-step approve for USDT compatibility
        IERC20(asset).approve(address(aavePool), 0);
        IERC20(asset).approve(address(aavePool), amount);
        uint256 amountRepaid = aavePool.repay(
            asset,
            amount,
            interestRateMode,
            debt
        );
        IERC20(asset).safeTransfer(msg.sender, amount - amountRepaid);
        emit Repay(debt, asset, amount, interestRateMode);
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
        IERC20(asset).approve(address(aavePool), 0);
        IERC20(asset).approve(address(aavePool), amount);
        uint256 amountRepaid = aavePool.repay(
            asset,
            amount,
            interestRateMode,
            debt
        );
        IERC20(asset).safeTransfer(msg.sender, amount - amountRepaid);
        aavePool.repay(asset, amount, interestRateMode, debt);

        emit Repay(debt, asset, amount, interestRateMode);
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

        emit Repay(debt, asset, amount, interestRateMode);
    }

    function callSwapBorrowRateMode(
        address debt,
        address asset,
        uint256 interestRateMode
    ) external {
        require(msg.sender == debtOwners[debt], "Not owner");
        IAaveDebt(debt).swapBorrowRateMode(asset, interestRateMode);
    }

    function executeFullSaleOrder(
        FullSellOrder calldata order,
        uint256 minProfit // based on base currency
    ) external {
        _verifyTitle(order.title);

        address debt = order.title.debt;
        address seller = debtOwners[debt];
        require(seller != address(0), "Invalid debt");

        // verify signature
        require(_verifyFullSellOrder(order, seller), "Invalid signature");

        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            ,
            ,
            ,
            uint256 hf
        ) = aavePool.getUserAccountData(debt);

        // check HF
        require(hf <= order.title.triggerHF, "HF too high");

        // calculate basePayValue based on fullSaleExtra
        uint256 basePayValue = (totalDebtBase * order.fullSaleExtra) /
            ONE_HUNDRED_PERCENT;

        // check profit
        require(
            totalCollateralBase - (totalDebtBase + basePayValue) >= minProfit,
            "Insufficient profit"
        );

        // convert totalDebtBase (in USD 1e8) to fullSaleToken amount
        uint256 fullSalePayValue = _getTokenValueFromBaseValue(
            basePayValue,
            order.fullSaleToken,
            aaveOracle.getAssetPrice(order.fullSaleToken)
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

        emit ExecuteFullSaleOrder(debt, order.title.debtNonce, msg.sender);
    }

    function excutePartialSellOrder(PartialSellOrder calldata order) external {
        _verifyTitle(order.title);

        address debt = order.title.debt;
        address seller = debtOwners[debt];
        require(seller != address(0), "Invalid debt");

        // verify signature
        require(_verifyPartialSellOrder(order, seller), "Invalid signature");

        (, , , , , uint256 initialHF) = aavePool.getUserAccountData(debt);

        // check HF
        require(initialHF <= order.title.triggerHF, "HF too high");

        // transfer repayAmount from buyer to contract
        IERC20(order.repayToken).safeTransferFrom(
            msg.sender,
            address(this),
            order.repayAmount
        );
        IERC20(order.repayToken).approve(address(aavePool), order.repayAmount);

        // repay debt with the correct rate mode
        aavePool.repay(
            order.repayToken,
            order.repayAmount,
            order.interestRateMode,
            debt
        );

        // calculate collateral amounts to withdraw
        uint256 repayAmountInBase = _getBaseValueFromTokenValue(
            order.repayToken,
            order.repayAmount,
            aaveOracle.getAssetPrice(order.repayToken)
        );

        uint256 totalPercent;
        // withdraw collaterals
        for (uint256 i = 0; i < order.collateralOut.length; i++) {
            totalPercent += order.percents[i];
            uint256 withdrawAmountInBase = (repayAmountInBase *
                order.percents[i]) / ONE_HUNDRED_PERCENT;
            uint256 withdrawAmountInToken = _getTokenValueFromBaseValue(
                withdrawAmountInBase,
                order.collateralOut[i],
                aaveOracle.getAssetPrice(order.collateralOut[i])
            );

            withdrawAmountInToken +=
                (withdrawAmountInToken * order.bonus) /
                ONE_HUNDRED_PERCENT;

            // withdraw collateral
            IAaveDebt(debt).withdraw(
                order.collateralOut[i],
                withdrawAmountInToken,
                msg.sender
            );
        }

        require(totalPercent == ONE_HUNDRED_PERCENT, "One hundred percent");

        // check final HF is better than initial HF
        (, , , , , uint256 finalHF) = aavePool.getUserAccountData(debt);
        require(finalHF > initialHF, "HF must improve");

        emit ExecutePartialSellOrder(debt, order.title.debtNonce, msg.sender);
    }

    function _getTokenValueFromBaseValue(
        uint256 baseValue, // 18 decimals
        address token,
        uint256 tokenPrice // 8 decimals
    ) public view returns (uint256) {
        uint8 tokenDecimals = IERC20Detailed(token).decimals();
        uint8 priceDecimals = 8;

        return
            (baseValue * 10 ** (tokenDecimals)) /
            (tokenPrice * 10 ** (18 - priceDecimals));
    }

    function _getBaseValueFromTokenValue(
        address token,
        uint256 tokenValue,
        uint256 tokenPrice
    ) public view returns (uint256) {
        uint8 tokenDecimals = IERC20Detailed(token).decimals();
        uint8 priceDecimals = 8;

        return
            (tokenValue * tokenPrice * 10 ** 18) /
            (10 ** (priceDecimals + tokenDecimals));
    }

    function _verifyTitle(OrderTitle calldata title) internal view {
        require(
            block.timestamp >= title.startTime &&
                block.timestamp <= title.endTime,
            "Order expired"
        );
        require(
            title.debtNonce == debtNonces[title.debt],
            "Invalid debt nonce"
        );
    }

    function _verifyFullSellOrder(
        FullSellOrder calldata order,
        address signer
    ) internal view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(
                FULL_SELL_ORDER_TYPE_HASH,
                block.chainid,
                address(this),
                _titleHash(order.title),
                order.fullSaleToken,
                order.fullSaleExtra
            )
        );

        return signer == ECDSA.recover(structHash, order.v, order.r, order.s);
    }

    function _verifyPartialSellOrder(
        PartialSellOrder calldata order,
        address signer
    ) internal view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(
                PARTIAL_SELL_ORDER_TYPE_HASH,
                block.chainid,
                address(this),
                _titleHash(order.title),
                order.interestRateMode,
                order.collateralOut,
                order.percents,
                order.repayToken,
                order.repayAmount,
                order.bonus
            )
        );
        return signer == ECDSA.recover(structHash, order.v, order.r, order.s);
    }

    function _titleHash(
        OrderTitle calldata title
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TITLE_TYPE_HASH,
                    title.debt,
                    title.debtNonce,
                    title.startTime,
                    title.endTime,
                    title.triggerHF
                )
            );
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
