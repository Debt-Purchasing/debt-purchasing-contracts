// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IAavePool
 * @dev Interface for the Aave Pool contract
 */
interface IAavePool {
    /**
     * @dev Supplies an amount of underlying asset to the protocol
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards
     */
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Allows users to borrow a specific amount of the reserve underlying asset
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards
     * @param onBehalfOf Address of the user who will receive the debt
     */
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @dev Repays a borrowed amount on a specific reserve
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt
     * @param interestRateMode The interest rate mode at which the user wants to borrow
     * @param onBehalfOf Address of the user who will get his debt reduced
     * @return The final amount repaid
     */
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Withdraws an amount of underlying asset from the reserve
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     * - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     * wants to receive it on his own wallet, or a different address if the beneficiary is a
     * different wallet
     * @return The final amount withdrawn
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral in base currency
     * @return totalDebtBase The total debt in base currency
     * @return availableBorrowsBase The borrowing power left of the user in base currency
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of the user
     * @return healthFactor The current health factor of the user
     */
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
} 