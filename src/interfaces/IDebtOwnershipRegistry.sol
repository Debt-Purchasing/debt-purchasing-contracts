// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IDebtOwnershipRegistry
 * @dev Interface for the DebtOwnershipRegistry contract
 */
interface IDebtOwnershipRegistry {
    /**
     * @dev Struct representing a debt position
     */
    struct DebtPosition {
        address borrower;
        address borrowedAsset;
        uint256 borrowedAmount;
        address collateralAsset;
        uint256 collateralAmount;
        uint256 interestRateMode;
        uint256 timestamp;
    }

    /**
     * @dev Emitted when a new debt position is registered
     * @param positionId The ID of the position
     * @param borrower The address of the borrower
     * @param borrowedAsset The address of the borrowed asset
     * @param borrowedAmount The amount of borrowed assets
     */
    event DebtPositionRegistered(
        uint256 indexed positionId,
        address indexed borrower,
        address borrowedAsset,
        uint256 borrowedAmount
    );

    /**
     * @dev Emitted when ownership of a debt position is transferred
     * @param positionId The ID of the position
     * @param from The previous owner
     * @param to The new owner
     */
    event DebtOwnershipTransferred(
        uint256 indexed positionId, address indexed from, address indexed to
    );

    /**
     * @dev Registers a new debt position
     * @param borrower The address of the borrower
     * @param borrowedAsset The address of the borrowed asset
     * @param borrowedAmount The amount of borrowed assets
     * @param collateralAsset The address of the collateral asset
     * @param collateralAmount The amount of collateral
     * @param interestRateMode The interest rate mode of the debt
     * @return positionId The ID of the registered position
     */
    function registerDebtPosition(
        address borrower,
        address borrowedAsset,
        uint256 borrowedAmount,
        address collateralAsset,
        uint256 collateralAmount,
        uint256 interestRateMode
    ) external returns (uint256 positionId);

    /**
     * @dev Transfers ownership of a debt position
     * @param positionId The ID of the position
     * @param to The address of the new owner
     */
    function transferOwnership(uint256 positionId, address to) external;

    /**
     * @dev Returns the owner of a debt position
     * @param positionId The ID of the position
     * @return The owner of the debt position
     */
    function getDebtPositionOwner(uint256 positionId) external view returns (address);

    /**
     * @dev Returns details of a debt position
     * @param positionId The ID of the position
     * @return The debt position details
     */
    function getDebtPosition(uint256 positionId) external view returns (DebtPosition memory);

    /**
     * @dev Returns the total number of debt positions
     * @return The total number of positions
     */
    function getPositionsCount() external view returns (uint256);
}
