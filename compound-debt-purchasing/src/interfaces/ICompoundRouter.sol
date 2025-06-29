// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ICompoundRouter {
    event CometVerified(address indexed comet);

    event CreateDebt(
        address indexed comet,
        address indexed debt,
        address indexed owner
    );
    event TransferDebtOwnership(address indexed debt, address indexed newOwner);
    event CancelCurrentDebtOrders(address indexed debt);
    event Supply(address indexed debt, address indexed asset, uint256 amount);
    event Borrow(
        address indexed debt,
        address indexed asset,
        uint256 amount,
        address to
    );
    event Repay(address indexed debt, address indexed asset, uint256 amount);
    event Withdraw(
        address indexed debt,
        address indexed asset,
        uint256 amount,
        address to
    );
}
