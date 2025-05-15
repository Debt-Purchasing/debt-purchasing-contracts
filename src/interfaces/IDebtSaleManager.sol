// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IDebtSaleManager
 * @dev Interface for the DebtSaleManager contract
 */
interface IDebtSaleManager {
    /**
     * @dev Struct representing a debt sale offer
     */
    struct DebtSaleOffer {
        address seller;
        address borrowedAsset;
        uint256 borrowedAmount;
        address collateralAsset;
        uint256 collateralAmount;
        uint256 price;
        uint256 interestRateMode;
        uint256 validUntil;
        bool isActive;
    }

    /**
     * @dev Emitted when a new debt sale offer is created
     * @param offerId The ID of the offer
     * @param seller The address of the seller
     * @param borrowedAsset The address of the borrowed asset
     * @param borrowedAmount The amount of borrowed assets
     * @param price The price for the debt position
     */
    event DebtOfferCreated(
        uint256 indexed offerId,
        address indexed seller,
        address borrowedAsset,
        uint256 borrowedAmount,
        uint256 price
    );

    /**
     * @dev Emitted when a debt sale is executed
     * @param offerId The ID of the offer
     * @param buyer The address of the buyer
     * @param seller The address of the seller
     * @param price The price paid for the debt position
     */
    event DebtSaleExecuted(
        uint256 indexed offerId, address indexed buyer, address indexed seller, uint256 price
    );

    /**
     * @dev Emitted when a debt sale offer is cancelled
     * @param offerId The ID of the offer
     * @param seller The address of the seller
     */
    event DebtOfferCancelled(uint256 indexed offerId, address indexed seller);

    /**
     * @dev Creates a new debt sale offer
     * @param borrowedAsset The address of the borrowed asset
     * @param collateralAsset The address of the collateral asset
     * @param price The price for the debt position
     * @param validUntil The timestamp until which the offer is valid
     * @param interestRateMode The interest rate mode of the debt
     * @return offerId The ID of the created offer
     */
    function createDebtOffer(
        address borrowedAsset,
        address collateralAsset,
        uint256 price,
        uint256 validUntil,
        uint256 interestRateMode
    ) external returns (uint256 offerId);

    /**
     * @dev Buys a debt position
     * @param offerId The ID of the offer
     */
    function buyDebtPosition(uint256 offerId) external payable;

    /**
     * @dev Cancels a debt sale offer
     * @param offerId The ID of the offer
     */
    function cancelDebtOffer(uint256 offerId) external;

    /**
     * @dev Returns details of a debt sale offer
     * @param offerId The ID of the offer
     * @return The debt sale offer details
     */
    function getDebtOffer(uint256 offerId) external view returns (DebtSaleOffer memory);

    /**
     * @dev Returns the total number of debt sale offers
     * @return The total number of offers
     */
    function getOffersCount() external view returns (uint256);
}
