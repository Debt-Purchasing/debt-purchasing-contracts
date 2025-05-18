// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAaveRouter {
    struct SellOrder {
        address debt;
        uint256 debtNonce;
        uint256 startTime;
        uint256 endTime;
        uint256 triggerHF;
        // fullSale
        bool isFullSale;
        address fullSaleToken;
        uint256 fullSaleExtra;
        // partialSale fields
        address[] collateralOut;
        uint256[] percents;
        address repayToken;
        uint256 repayAmount;
        uint256 bonus;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}
