// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ChainlinkMockAggregator} from "./mocks/ChainlinkMockAggregator.sol";

contract OracleManager {
    // Events
    event PricesUpdated(address[] oracles, uint256[] prices);
    event SinglePriceUpdated(address oracle, uint256 price);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // State variables
    address public owner;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "OracleManager: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @notice Update multiple oracle prices in a single transaction
     * @param oracles Array of ChainlinkMockAggregator oracle addresses
     * @param prices Array of new prices (8 decimal precision)
     */
    function updatePrices(
        address[] calldata oracles,
        uint256[] calldata prices
    ) external onlyOwner {
        require(
            oracles.length == prices.length,
            "OracleManager: arrays length mismatch"
        );
        require(oracles.length > 0, "OracleManager: empty arrays");

        for (uint256 i = 0; i < oracles.length; i++) {
            require(
                oracles[i] != address(0),
                "OracleManager: invalid oracle address"
            );

            ChainlinkMockAggregator oracle = ChainlinkMockAggregator(
                oracles[i]
            );
            oracle.updateAnswer(int256(prices[i]));
        }

        emit PricesUpdated(oracles, prices);
    }

    /**
     * @notice Update a single oracle price
     * @param oracle ChainlinkMockAggregator oracle address
     * @param price New price (8 decimal precision)
     */
    function updateSinglePrice(
        address oracle,
        uint256 price
    ) external onlyOwner {
        require(oracle != address(0), "OracleManager: invalid oracle address");

        ChainlinkMockAggregator mockOracle = ChainlinkMockAggregator(oracle);
        mockOracle.updateAnswer(int256(price));

        emit SinglePriceUpdated(oracle, price);
    }

    /**
     * @notice Get current price from an oracle
     * @param oracle ChainlinkMockAggregator oracle address
     * @return Current price from the oracle
     */
    function getCurrentPrice(address oracle) external view returns (int256) {
        require(oracle != address(0), "OracleManager: invalid oracle address");

        ChainlinkMockAggregator mockOracle = ChainlinkMockAggregator(oracle);
        return mockOracle.latestAnswer();
    }

    /**
     * @notice Get current prices from multiple oracles
     * @param oracles Array of ChainlinkMockAggregator oracle addresses
     * @return prices Array of current prices from the oracles
     */
    function getCurrentPrices(
        address[] calldata oracles
    ) external view returns (int256[] memory prices) {
        prices = new int256[](oracles.length);

        for (uint256 i = 0; i < oracles.length; i++) {
            require(
                oracles[i] != address(0),
                "OracleManager: invalid oracle address"
            );
            ChainlinkMockAggregator mockOracle = ChainlinkMockAggregator(
                oracles[i]
            );
            prices[i] = mockOracle.latestAnswer();
        }
    }

    /**
     * @notice Batch update with price scenarios
     * @param oracles Array of oracle addresses
     * @param scenario Price scenario: 0=baseline, 1=crash(-50%), 2=bull(+30%), 3=stablecoin_depeg
     */
    function updateScenario(
        address[] calldata oracles,
        uint256 scenario
    ) external onlyOwner {
        require(
            oracles.length == 12,
            "OracleManager: must provide exactly 12 oracles"
        );

        // Baseline prices for 12 tokens (WETH, wstETH, WBTC, USDC, DAI, LINK, AAVE, cbETH, USDT, rETH, LUSD, CRV)
        uint256[12] memory baselinePrices = [
            uint256(256292441874), // WETH: $2,563
            uint256(295649548839), // wstETH: $2,956
            uint256(4282587327281), // WBTC: $42,826
            uint256(100010301), // USDC: $1.00
            uint256(99995511), // DAI: $0.99
            uint256(1421619000), // LINK: $14.21
            uint256(10647761599), // AAVE: $106.47
            uint256(271107519445), // cbETH: $2,711
            uint256(99978000), // USDT: $0.99
            uint256(280710179813), // rETH: $2,807
            uint256(100803537), // LUSD: $1.008
            uint256(55057237) // CRV: $0.55
        ];

        uint256[] memory newPrices = new uint256[](12);

        if (scenario == 0) {
            // Baseline
            for (uint256 i = 0; i < 12; i++) {
                newPrices[i] = baselinePrices[i];
            }
        } else if (scenario == 1) {
            // Crash -50%
            for (uint256 i = 0; i < 12; i++) {
                if (i == 3 || i == 4 || i == 8 || i == 10) {
                    // Stablecoins stay stable
                    newPrices[i] = baselinePrices[i];
                } else {
                    newPrices[i] = (baselinePrices[i] * 50) / 100;
                }
            }
        } else if (scenario == 2) {
            // Bull +30%
            for (uint256 i = 0; i < 12; i++) {
                if (i == 3 || i == 4 || i == 8 || i == 10) {
                    // Stablecoins stay stable
                    newPrices[i] = baselinePrices[i];
                } else {
                    newPrices[i] = (baselinePrices[i] * 130) / 100;
                }
            }
        } else if (scenario == 3) {
            // Stablecoin depeg
            for (uint256 i = 0; i < 12; i++) {
                if (i == 3 || i == 4 || i == 8) {
                    // USDC, DAI, USDT depeg to $0.85
                    newPrices[i] = 85000000;
                } else {
                    newPrices[i] = baselinePrices[i];
                }
            }
        } else {
            revert("OracleManager: invalid scenario");
        }

        // Update all oracles
        for (uint256 i = 0; i < oracles.length; i++) {
            ChainlinkMockAggregator oracle = ChainlinkMockAggregator(
                oracles[i]
            );
            oracle.updateAnswer(int256(newPrices[i]));
        }

        emit PricesUpdated(oracles, newPrices);
    }

    /**
     * @notice Transfer ownership of the contract
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "OracleManager: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice Renounce ownership of the contract
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}
