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
        address fullSaleToken;
        uint256 fullSaleExtra;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PartialSellOrder {
        OrderTitle title;
        uint256 interestRateMode;
        uint256 minHF;
        address[] collateralOut;
        uint256[] percents;
        address repayToken;
        uint256 repayAmount;
        uint256 bonus;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event ExecuteFullSaleOrder(
        address indexed debt,
        uint256 debtNonce,
        address buyer
    );

    event ExecutePartialSellOrder(
        address indexed debt,
        uint256 debtNonce,
        address buyer
    );
}
