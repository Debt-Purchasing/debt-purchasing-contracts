// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IDebtVault
 * @dev Interface for the DebtVault contract
 */
interface IDebtVault {
    /**
     * @dev Emitted when a user deposits collateral
     * @param user The address of the user
     * @param asset The address of the asset
     * @param amount The amount deposited
     */
    event CollateralDeposited(address indexed user, address indexed asset, uint256 amount);

    /**
     * @dev Emitted when a user borrows assets
     * @param user The address of the user
     * @param asset The address of the asset
     * @param amount The amount borrowed
     */
    event AssetBorrowed(address indexed user, address indexed asset, uint256 amount);

    /**
     * @dev Emitted when a user repays debt
     * @param user The address of the user
     * @param asset The address of the asset
     * @param amount The amount repaid
     */
    event DebtRepaid(address indexed user, address indexed asset, uint256 amount);

    /**
     * @dev Emitted when a user withdraws collateral
     * @param user The address of the user
     * @param asset The address of the asset
     * @param amount The amount withdrawn
     */
    event CollateralWithdrawn(address indexed user, address indexed asset, uint256 amount);

    /**
     * @dev Deposits collateral into Aave
     * @param asset The address of the asset to deposit
     * @param amount The amount to deposit
     */
    function depositCollateral(address asset, uint256 amount) external;

    /**
     * @dev Borrows assets from Aave
     * @param asset The address of the asset to borrow
     * @param amount The amount to borrow
     * @param interestRateMode The interest rate mode (1 for stable, 2 for variable)
     */
    function borrowAsset(address asset, uint256 amount, uint256 interestRateMode) external;

    /**
     * @dev Repays debt to Aave
     * @param asset The address of the asset to repay
     * @param amount The amount to repay
     * @param interestRateMode The interest rate mode of the debt to repay
     */
    function repayDebt(address asset, uint256 amount, uint256 interestRateMode) external;

    /**
     * @dev Withdraws collateral from Aave
     * @param asset The address of the asset to withdraw
     * @param amount The amount to withdraw
     */
    function withdrawCollateral(address asset, uint256 amount) external;

    /**
     * @dev Gets user account data from Aave
     * @param user The address of the user
     */
    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
} 