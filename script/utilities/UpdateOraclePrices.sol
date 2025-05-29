// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ChainlinkMockAggregator} from "../deploy-aavev3-sepolia/mocks/ChainlinkMockAggregator.sol";

contract UpdateOraclePrices is Script {
    // Production deployment oracle addresses (will be set after deployment)
    // These should be updated after running deploy_production_aave_v3_local.sh
    mapping(string => address) public oracleAddresses;

    // Current mainnet prices (as baseline)
    mapping(string => int256) public baselinePrices;

    function setUp() internal {
        // Set baseline prices from mainnet analysis
        baselinePrices["WETH"] = 256292441874; // $2,563
        baselinePrices["wstETH"] = 295649548839; // $2,956
        baselinePrices["WBTC"] = 4282587327281; // $42,826
        baselinePrices["USDC"] = 100010301; // $1.00
        baselinePrices["DAI"] = 99995511; // $0.99
        baselinePrices["LINK"] = 1421619000; // $14.21
        baselinePrices["AAVE"] = 10647761599; // $106.47
        baselinePrices["cbETH"] = 271107519445; // $2,711
        baselinePrices["USDT"] = 99978000; // $0.99
        baselinePrices["rETH"] = 280710179813; // $2,807
        baselinePrices["LUSD"] = 100803537; // $1.008
        baselinePrices["CRV"] = 55057237; // $0.55
    }

    function run() external {
        setUp();

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("=== Oracle Price Update Utility ===");
        console.log("Choose update scenario:");
        console.log("1. Reset to baseline mainnet prices");
        console.log("2. Crash scenario (-50% for all assets)");
        console.log("3. Bull market (+30% for all assets)");
        console.log("4. Stablecoin depeg (USDC/DAI/USDT to $0.85)");
        console.log("5. ETH pump (+20% ETH ecosystem)");
        console.log("6. Custom price update");
        console.log("=====================================");

        vm.stopBroadcast();
    }

    function resetToBaseline() external {
        setUp();

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("Resetting all prices to mainnet baseline...");

        updateTokenPrice("WETH", baselinePrices["WETH"]);
        updateTokenPrice("wstETH", baselinePrices["wstETH"]);
        updateTokenPrice("WBTC", baselinePrices["WBTC"]);
        updateTokenPrice("USDC", baselinePrices["USDC"]);
        updateTokenPrice("DAI", baselinePrices["DAI"]);
        updateTokenPrice("LINK", baselinePrices["LINK"]);
        updateTokenPrice("AAVE", baselinePrices["AAVE"]);
        updateTokenPrice("cbETH", baselinePrices["cbETH"]);
        updateTokenPrice("USDT", baselinePrices["USDT"]);
        updateTokenPrice("rETH", baselinePrices["rETH"]);
        updateTokenPrice("LUSD", baselinePrices["LUSD"]);
        updateTokenPrice("CRV", baselinePrices["CRV"]);

        console.log("All prices reset to mainnet baseline");

        vm.stopBroadcast();
    }

    function crashScenario() external {
        setUp();

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("CRASH SCENARIO: -50% for all assets");

        updateTokenPrice("WETH", (baselinePrices["WETH"] * 50) / 100);
        updateTokenPrice("wstETH", (baselinePrices["wstETH"] * 50) / 100);
        updateTokenPrice("WBTC", (baselinePrices["WBTC"] * 50) / 100);
        updateTokenPrice("USDC", baselinePrices["USDC"]); // Stablecoins stay stable
        updateTokenPrice("DAI", baselinePrices["DAI"]);
        updateTokenPrice("LINK", (baselinePrices["LINK"] * 50) / 100);
        updateTokenPrice("AAVE", (baselinePrices["AAVE"] * 50) / 100);
        updateTokenPrice("cbETH", (baselinePrices["cbETH"] * 50) / 100);
        updateTokenPrice("USDT", baselinePrices["USDT"]);
        updateTokenPrice("rETH", (baselinePrices["rETH"] * 50) / 100);
        updateTokenPrice("LUSD", baselinePrices["LUSD"]);
        updateTokenPrice("CRV", (baselinePrices["CRV"] * 50) / 100);

        console.log(
            "Crash scenario applied - Health Factors should drop significantly"
        );

        vm.stopBroadcast();
    }

    function bullMarket() external {
        setUp();

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("BULL MARKET: +30% for all assets");

        updateTokenPrice("WETH", (baselinePrices["WETH"] * 130) / 100);
        updateTokenPrice("wstETH", (baselinePrices["wstETH"] * 130) / 100);
        updateTokenPrice("WBTC", (baselinePrices["WBTC"] * 130) / 100);
        updateTokenPrice("USDC", baselinePrices["USDC"]); // Stablecoins stay stable
        updateTokenPrice("DAI", baselinePrices["DAI"]);
        updateTokenPrice("LINK", (baselinePrices["LINK"] * 130) / 100);
        updateTokenPrice("AAVE", (baselinePrices["AAVE"] * 130) / 100);
        updateTokenPrice("cbETH", (baselinePrices["cbETH"] * 130) / 100);
        updateTokenPrice("USDT", baselinePrices["USDT"]);
        updateTokenPrice("rETH", (baselinePrices["rETH"] * 130) / 100);
        updateTokenPrice("LUSD", baselinePrices["LUSD"]);
        updateTokenPrice("CRV", (baselinePrices["CRV"] * 130) / 100);

        console.log("Bull market applied - Health Factors should improve");

        vm.stopBroadcast();
    }

    function stablecoinDepeg() external {
        setUp();

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("WARNING STABLECOIN DEPEG: USDC/DAI/USDT to $0.85");

        int256 depegPrice = 85000000; // $0.85 in 8 decimals

        updateTokenPrice("USDC", depegPrice);
        updateTokenPrice("DAI", depegPrice);
        updateTokenPrice("USDT", depegPrice);
        // Keep LUSD stable as it's algorithmic
        updateTokenPrice("LUSD", baselinePrices["LUSD"]);

        console.log(
            "Stablecoin depeg applied - Borrowers with stablecoin collateral at risk"
        );

        vm.stopBroadcast();
    }

    function ethPump() external {
        setUp();

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("ETH PUMP: +20% for ETH ecosystem");

        updateTokenPrice("WETH", (baselinePrices["WETH"] * 120) / 100);
        updateTokenPrice("wstETH", (baselinePrices["wstETH"] * 120) / 100);
        updateTokenPrice("cbETH", (baselinePrices["cbETH"] * 120) / 100);
        updateTokenPrice("rETH", (baselinePrices["rETH"] * 120) / 100);

        // Other assets unchanged
        updateTokenPrice("WBTC", baselinePrices["WBTC"]);
        updateTokenPrice("USDC", baselinePrices["USDC"]);
        updateTokenPrice("DAI", baselinePrices["DAI"]);
        updateTokenPrice("LINK", baselinePrices["LINK"]);
        updateTokenPrice("AAVE", baselinePrices["AAVE"]);
        updateTokenPrice("USDT", baselinePrices["USDT"]);
        updateTokenPrice("LUSD", baselinePrices["LUSD"]);
        updateTokenPrice("CRV", baselinePrices["CRV"]);

        console.log("ETH ecosystem pump applied");

        vm.stopBroadcast();
    }

    function updateSingleToken(string memory symbol, int256 newPrice) external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        updateTokenPrice(symbol, newPrice);

        vm.stopBroadcast();
    }

    function updateTokenPrice(string memory symbol, int256 newPrice) internal {
        address oracleAddr = oracleAddresses[symbol];
        require(
            oracleAddr != address(0),
            string.concat("Oracle not found for ", symbol)
        );

        ChainlinkMockAggregator oracle = ChainlinkMockAggregator(oracleAddr);
        oracle.updateAnswer(newPrice);

        console.log(
            string.concat(symbol, " price updated to:"),
            uint256(newPrice)
        );
    }

    // Function to set oracle addresses after deployment
    function setOracleAddresses(
        address[] memory oracles,
        string[] memory symbols
    ) external {
        require(oracles.length == symbols.length, "Arrays length mismatch");

        for (uint i = 0; i < oracles.length; i++) {
            oracleAddresses[symbols[i]] = oracles[i];
        }
    }

    // Helper function to get current price from oracle
    function getCurrentPrice(
        string memory symbol
    ) external view returns (int256) {
        address oracleAddr = oracleAddresses[symbol];
        require(
            oracleAddr != address(0),
            string.concat("Oracle not found for ", symbol)
        );

        ChainlinkMockAggregator oracle = ChainlinkMockAggregator(oracleAddr);
        return oracle.latestAnswer();
    }
}
