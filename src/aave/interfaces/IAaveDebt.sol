// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

interface IAaveDebt {
    function initialize(IPool _pool) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address receiver
    ) external;

    function withdraw(address asset, uint256 amount, address to) external;

    function repayWithATokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address sender
    ) external;

    function swapBorrowRateMode(
        address asset,
        uint256 interestRateMode
    ) external;
}
