// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IAavePool.sol";
import "./interfaces/IAavePoolAddressesProvider.sol";
import "./interfaces/IDebtVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title DebtVault
 * @dev Contract for managing user deposits and borrows on Aave
 */
contract DebtVault is IDebtVault, Ownable {
    using SafeERC20 for IERC20;

    // Aave PoolAddressesProvider address
    IAavePoolAddressesProvider public immutable poolAddressesProvider;

    // Aave referral code for integrators
    uint16 public constant REFERRAL_CODE = 0;

    /**
     * @dev Constructor
     * @param _poolAddressesProvider The address of the Aave PoolAddressesProvider
     */
    constructor(address _poolAddressesProvider) Ownable(msg.sender) {
        require(_poolAddressesProvider != address(0), "Invalid pool addresses provider");
        poolAddressesProvider = IAavePoolAddressesProvider(_poolAddressesProvider);
    }

    /**
     * @dev Deposits collateral into Aave
     * @param asset The address of the asset to deposit
     * @param amount The amount to deposit
     */
    function depositCollateral(address asset, uint256 amount) external override {
        require(asset != address(0), "Invalid asset address");
        require(amount > 0, "Amount must be greater than 0");

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        // Approve Aave to use the tokens
        IERC20(asset).safeApprove(address(_getPool()), amount);

        // Supply to Aave
        _getPool().supply(asset, amount, msg.sender, REFERRAL_CODE);

        emit CollateralDeposited(msg.sender, asset, amount);
    }

    /**
     * @dev Borrows assets from Aave
     * @param asset The address of the asset to borrow
     * @param amount The amount to borrow
     * @param interestRateMode The interest rate mode (1 for stable, 2 for variable)
     */
    function borrowAsset(address asset, uint256 amount, uint256 interestRateMode)
        external
        override
    {
        require(asset != address(0), "Invalid asset address");
        require(amount > 0, "Amount must be greater than 0");
        require(interestRateMode == 1 || interestRateMode == 2, "Invalid interest rate mode");

        // Borrow from Aave
        _getPool().borrow(asset, amount, interestRateMode, REFERRAL_CODE, msg.sender);

        emit AssetBorrowed(msg.sender, asset, amount);
    }

    /**
     * @dev Repays debt to Aave
     * @param asset The address of the asset to repay
     * @param amount The amount to repay
     * @param interestRateMode The interest rate mode of the debt to repay
     */
    function repayDebt(address asset, uint256 amount, uint256 interestRateMode) external override {
        require(asset != address(0), "Invalid asset address");
        require(amount > 0, "Amount must be greater than 0");
        require(interestRateMode == 1 || interestRateMode == 2, "Invalid interest rate mode");

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        // Approve Aave to use the tokens
        IERC20(asset).safeApprove(address(_getPool()), amount);

        // Repay to Aave
        _getPool().repay(asset, amount, interestRateMode, msg.sender);

        emit DebtRepaid(msg.sender, asset, amount);
    }

    /**
     * @dev Withdraws collateral from Aave
     * @param asset The address of the asset to withdraw
     * @param amount The amount to withdraw
     */
    function withdrawCollateral(address asset, uint256 amount) external override {
        require(asset != address(0), "Invalid asset address");
        require(amount > 0, "Amount must be greater than 0");

        // Withdraw from Aave
        _getPool().withdraw(asset, amount, msg.sender);

        emit CollateralWithdrawn(msg.sender, asset, amount);
    }

    /**
     * @dev Gets user account data from Aave
     * @param user The address of the user
     */
    function getUserAccountData(address user)
        external
        view
        override
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return _getPool().getUserAccountData(user);
    }

    /**
     * @dev Gets the Aave Pool instance
     * @return The Aave Pool
     */
    function _getPool() internal view returns (IAavePool) {
        return IAavePool(poolAddressesProvider.getPool());
    }
}
