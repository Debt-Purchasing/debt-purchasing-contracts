// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IAavePoolAddressesProvider
 * @dev Interface for the Aave PoolAddressesProvider contract
 */
interface IAavePoolAddressesProvider {
    /**
     * @dev Returns the address of the Pool proxy
     * @return The Pool proxy address
     */
    function getPool() external view returns (address);

    /**
     * @dev Returns the address of the price oracle
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @dev Returns the address of the price oracle sentinel
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);
} 