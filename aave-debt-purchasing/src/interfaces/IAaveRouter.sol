// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAaveRouter {
    struct OrderTitle {
        address debt;
        uint256 debtNonce;
        uint256 startTime;
        uint256 endTime;
        uint256 triggerHF;
    }

    struct FullSellOrder {
        OrderTitle title;
        address token;
        uint256 percentOfEquity;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PartialSellOrder {
        OrderTitle title;
        uint256 interestRateMode;
        address collateralOut;
        address repayToken;
        uint256 repayAmount;
        uint256 bonus;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event CreateDebt(
        address indexed debt,
        address indexed owner,
        uint256 nonce
    );
    event TransferDebtOwnership(address indexed debt, address indexed newOwner);
    event CancelCurrentDebtOrders(address indexed debt);
    event CancelOrder(bytes32 indexed titleHash);
    event Supply(address indexed debt, address indexed asset, uint256 amount);
    event Borrow(
        address indexed debt,
        address indexed asset,
        uint256 amount,
        uint256 interestRateMode
    );
    event Withdraw(
        address indexed debt,
        address indexed asset,
        uint256 amount,
        address to
    );
    event Repay(
        address indexed debt,
        address indexed asset,
        uint256 amount,
        uint256 interestRateMode
    );

    event ExecuteFullSaleOrder(
        bytes32 indexed titleHash,
        address indexed debt,
        uint256 debtNonce,
        address seller,
        address buyer,
        uint256 baseValue
    );

    event ExecutePartialSellOrder(
        bytes32 indexed titleHash,
        address indexed debt,
        uint256 debtNonce,
        address seller,
        address buyer,
        uint256 baseValue
    );
}
