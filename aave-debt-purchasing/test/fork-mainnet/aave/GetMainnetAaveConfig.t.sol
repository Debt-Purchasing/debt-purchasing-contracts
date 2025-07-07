// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPoolConfigurator.sol";
import "@aave/core-v3/contracts/interfaces/IPriceOracleGetter.sol";
import "@aave/core-v3/contracts/interfaces/IAToken.sol";
import "@aave/core-v3/contracts/interfaces/IDefaultInterestRateStrategy.sol";
import "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import "@aave/core-v3/contracts/protocol/libraries/configuration/ReserveConfiguration.sol";
import "./helpers/IERC20Metadata.sol";

/**
 * @title GetMainnetAaveConfig
 * @notice Test contract to fork mainnet and extract real Aave V3 configurations
 * @dev Used to verify and get accurate parameters for Sepolia deployment
 */
contract GetMainnetAaveConfig is Test {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    // Official Aave V3 Mainnet addresses from https://aave.com/docs/resources/addresses
    address public constant AAVE_V3_POOL =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant AAVE_V3_POOL_ADDRESSES_PROVIDER =
        0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address public constant AAVE_V3_POOL_CONFIGURATOR =
        0x64b761D848206f447Fe2dd461b0c635Ec39EbB27;
    address public constant AAVE_V3_ORACLE =
        0x54586bE62E3c3580375aE3723C145253060Ca0C2;
    address public constant AAVE_V3_ACL_MANAGER =
        0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0;

    // Production token addresses from Aave V3 Ethereum Core Market
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant cbETH = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant rETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address public constant LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    // Contract interfaces
    IPool public pool;
    IPoolAddressesProvider public addressesProvider;
    IPriceOracleGetter public oracle;

    // Array of all production tokens
    address[] public tokens;
    string[] public tokenSymbols;

    function setUp() public {
        // Fork mainnet at a recent block
        uint256 forkId = vm.createFork(vm.rpcUrl("mainnet"), 19000000);
        vm.selectFork(forkId);

        // Initialize contracts
        pool = IPool(AAVE_V3_POOL);
        addressesProvider = IPoolAddressesProvider(
            AAVE_V3_POOL_ADDRESSES_PROVIDER
        );
        oracle = IPriceOracleGetter(AAVE_V3_ORACLE);

        // Initialize token arrays
        tokens = [
            WETH,
            wstETH,
            WBTC,
            USDC,
            DAI,
            LINK,
            AAVE,
            cbETH,
            USDT,
            rETH,
            LUSD,
            CRV
        ];
        tokenSymbols = [
            "WETH",
            "wstETH",
            "WBTC",
            "USDC",
            "DAI",
            "LINK",
            "AAVE",
            "cbETH",
            "USDT",
            "rETH",
            "LUSD",
            "CRV"
        ];
    }

    /**
     * @notice Extract and display all token configurations from mainnet Aave V3
     */
    function testGetAllTokenConfigurations() public view {
        console.log(
            "================================================================================"
        );
        console.log("AAVE V3 MAINNET TOKEN CONFIGURATIONS");
        console.log(
            "================================================================================"
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            string memory symbol = tokenSymbols[i];

            // Check if reserve exists
            try pool.getReserveData(token) returns (
                DataTypes.ReserveData memory reserveData
            ) {
                if (reserveData.aTokenAddress == address(0)) {
                    console.log("%s: NOT CONFIGURED IN AAVE V3", symbol);
                    console.log("");
                    continue;
                }

                _displayTokenConfig(token, symbol);
            } catch {
                console.log("%s: ERROR GETTING RESERVE DATA", symbol);
                console.log("");
            }
        }
    }

    /**
     * @notice Display comprehensive configuration for a specific token
     */
    function _displayTokenConfig(
        address token,
        string memory symbol
    ) internal view {
        console.log(
            "------------------------------------------------------------"
        );
        console.log("TOKEN: %s (%s)", symbol, token);
        console.log(
            "------------------------------------------------------------"
        );

        // Get basic token info
        IERC20Metadata tokenContract = IERC20Metadata(token);
        console.log("Name: %s", tokenContract.name());
        console.log("Symbol: %s", tokenContract.symbol());
        console.log("Decimals: %s", tokenContract.decimals());

        // Get reserve data
        DataTypes.ReserveData memory reserveData = pool.getReserveData(token);
        DataTypes.ReserveConfigurationMap memory config = pool.getConfiguration(
            token
        );

        // // Extract configuration values
        // uint256 ltv = config.getLtv();
        // uint256 liquidationThreshold = config.getLiquidationThreshold();
        // uint256 liquidationBonus = config.getLiquidationBonus();
        // uint256 reserveFactor = config.getReserveFactor();
        // bool isActive = config.getActive();
        // bool isFrozen = config.getFrozen();
        // bool borrowingEnabled = config.getBorrowingEnabled();
        // bool stableBorrowRateEnabled = config.getStableRateBorrowingEnabled();
        // bool isPaused = config.getPaused();
        // uint256 supplyCap = config.getSupplyCap();
        // uint256 borrowCap = config.getBorrowCap();

        // // Get current price
        // uint256 price = oracle.getAssetPrice(token);

        // console.log("");
        // console.log("BASIC INFO:");
        // console.log("  aToken: %s", reserveData.aTokenAddress);
        // console.log(
        //     "  Variable Debt Token: %s",
        //     reserveData.variableDebtTokenAddress
        // );
        // console.log(
        //     "  Stable Debt Token: %s",
        //     reserveData.stableDebtTokenAddress
        // );
        // console.log("  Current Price: %s (8 decimals)", price);

        // console.log("");
        // console.log("RISK PARAMETERS:");
        // console.log("  LTV: %s basis points (%s%%)", ltv, ltv / 100);
        // console.log(
        //     "  Liquidation Threshold: %s basis points (%s%%)",
        //     liquidationThreshold,
        //     liquidationThreshold / 100
        // );
        // console.log(
        //     "  Liquidation Bonus: %s basis points (%s%%)",
        //     liquidationBonus,
        //     liquidationBonus / 100
        // );
        // console.log(
        //     "  Reserve Factor: %s basis points (%s%%)",
        //     reserveFactor,
        //     reserveFactor / 100
        // );

        // console.log("");
        // console.log("CAPS:");
        // console.log("  Supply Cap: %s", supplyCap);
        // console.log("  Borrow Cap: %s", borrowCap);

        // console.log("");
        // console.log("STATUS FLAGS:");
        // console.log("  Is Active: %s", isActive);
        // console.log("  Is Frozen: %s", isFrozen);
        // console.log("  Is Paused: %s", isPaused);
        // console.log("  Borrowing Enabled: %s", borrowingEnabled);
        // console.log("  Stable Borrow Enabled: %s", stableBorrowRateEnabled);

        // Get interest rate strategy
        _displayInterestRateStrategy(
            reserveData.interestRateStrategyAddress,
            symbol
        );

        console.log("");
    }

    /**
     * @notice Display interest rate strategy parameters
     */
    function _displayInterestRateStrategy(
        address strategyAddress,
        string memory symbol
    ) internal view {
        console.log("");
        console.log("INTEREST RATE STRATEGY (%s):", strategyAddress);

        try
            IDefaultInterestRateStrategy(strategyAddress).OPTIMAL_USAGE_RATIO()
        returns (uint256 optimalUsageRatio) {
            uint256 baseVariableBorrowRate = IDefaultInterestRateStrategy(
                strategyAddress
            ).getBaseVariableBorrowRate();
            uint256 variableRateSlope1 = IDefaultInterestRateStrategy(
                strategyAddress
            ).getVariableRateSlope1();
            uint256 variableRateSlope2 = IDefaultInterestRateStrategy(
                strategyAddress
            ).getVariableRateSlope2();
            uint256 stableRateSlope1 = IDefaultInterestRateStrategy(
                strategyAddress
            ).getStableRateSlope1();
            uint256 stableRateSlope2 = IDefaultInterestRateStrategy(
                strategyAddress
            ).getStableRateSlope2();

            console.log(
                "  Optimal Usage Ratio: %s (Ray) = %s%%",
                optimalUsageRatio,
                (optimalUsageRatio * 100) / 1e27
            );
            console.log(
                "  Base Variable Borrow Rate: %s (Ray) = %s%%",
                baseVariableBorrowRate,
                (baseVariableBorrowRate * 100) / 1e27
            );
            console.log(
                "  Variable Rate Slope 1: %s (Ray) = %s%%",
                variableRateSlope1,
                (variableRateSlope1 * 100) / 1e27
            );
            console.log(
                "  Variable Rate Slope 2: %s (Ray) = %s%%",
                variableRateSlope2,
                (variableRateSlope2 * 100) / 1e27
            );
            console.log(
                "  Stable Rate Slope 1: %s (Ray) = %s%%",
                stableRateSlope1,
                (stableRateSlope1 * 100) / 1e27
            );
            console.log(
                "  Stable Rate Slope 2: %s (Ray) = %s%%",
                stableRateSlope2,
                (stableRateSlope2 * 100) / 1e27
            );
        } catch {
            console.log(
                "  ERROR: Could not read interest rate strategy parameters"
            );
        }
    }

    /**
     * @notice Generate TokenConfig struct format for easy copy-paste
     */
    function testGenerateTokenConfigStructs() public view {
        console.log(
            "================================================================================"
        );
        console.log("TOKENCONFIG STRUCTS FOR SEPOLIA DEPLOYMENT");
        console.log(
            "================================================================================"
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            string memory symbol = tokenSymbols[i];

            try pool.getReserveData(token) returns (
                DataTypes.ReserveData memory reserveData
            ) {
                if (reserveData.aTokenAddress == address(0)) {
                    continue;
                }

                _generateTokenConfigStruct(token, symbol);
            } catch {
                continue;
            }
        }
    }

    /**
     * @notice Generate TokenConfig struct for a specific token
     */
    function _generateTokenConfigStruct(
        address token,
        string memory symbol
    ) internal view {
        IERC20Metadata tokenContract = IERC20Metadata(token);
        DataTypes.ReserveData memory reserveData = pool.getReserveData(token);
        DataTypes.ReserveConfigurationMap memory config = pool.getConfiguration(
            token
        );

        // Get price
        uint256 price = oracle.getAssetPrice(token);

        // Get interest rate strategy parameters
        address strategyAddress = reserveData.interestRateStrategyAddress;

        console.log("TokenConfig({");
        console.log('    name: "%s",', tokenContract.name());
        console.log('    symbol: "%s",', tokenContract.symbol());
        console.log("    decimals: %s,", tokenContract.decimals());
        console.log("    initialPrice: %s, // $%s", price, price / 1e8);
        console.log(
            "    ltv: %s, // %s%%",
            config.getLtv(),
            config.getLtv() / 100
        );
        console.log(
            "    liquidationThreshold: %s, // %s%%",
            config.getLiquidationThreshold(),
            config.getLiquidationThreshold() / 100
        );
        console.log(
            "    liquidationBonus: %s, // %s%%",
            config.getLiquidationBonus(),
            config.getLiquidationBonus() / 100
        );
        console.log(
            "    reserveFactor: %s, // %s%%",
            config.getReserveFactor(),
            config.getReserveFactor() / 100
        );
        console.log("    borrowingEnabled: %s,", config.getBorrowingEnabled());
        console.log(
            "    stableBorrowRateEnabled: %s,",
            config.getStableRateBorrowingEnabled()
        );

        try
            IDefaultInterestRateStrategy(strategyAddress).OPTIMAL_USAGE_RATIO()
        returns (uint256 optimalUsageRatio) {
            uint256 baseVariableBorrowRate = IDefaultInterestRateStrategy(
                strategyAddress
            ).getBaseVariableBorrowRate();
            uint256 variableRateSlope1 = IDefaultInterestRateStrategy(
                strategyAddress
            ).getVariableRateSlope1();
            uint256 variableRateSlope2 = IDefaultInterestRateStrategy(
                strategyAddress
            ).getVariableRateSlope2();
            uint256 stableRateSlope1 = IDefaultInterestRateStrategy(
                strategyAddress
            ).getStableRateSlope1();
            uint256 stableRateSlope2 = IDefaultInterestRateStrategy(
                strategyAddress
            ).getStableRateSlope2();

            console.log(
                "    optimalUsageRatio: %se27, // %s%%",
                optimalUsageRatio / 1e27,
                (optimalUsageRatio * 100) / 1e27
            );
            console.log(
                "    baseVariableBorrowRate: %se27, // %s%%",
                baseVariableBorrowRate / 1e27,
                (baseVariableBorrowRate * 100) / 1e27
            );
            console.log(
                "    variableRateSlope1: %se27, // %s%%",
                variableRateSlope1 / 1e27,
                (variableRateSlope1 * 100) / 1e27
            );
            console.log(
                "    variableRateSlope2: %se27, // %s%%",
                variableRateSlope2 / 1e27,
                (variableRateSlope2 * 100) / 1e27
            );
            console.log(
                "    stableRateSlope1: %se27, // %s%%",
                stableRateSlope1 / 1e27,
                (stableRateSlope1 * 100) / 1e27
            );
            console.log(
                "    stableRateSlope2: %se27 // %s%%",
                stableRateSlope2 / 1e27,
                (stableRateSlope2 * 100) / 1e27
            );
        } catch {
            console.log("    // ERROR: Could not read interest rate strategy");
        }

        console.log("}), // %s", symbol);
        console.log("");
    }

    /**
     * @notice Test specific token configuration
     */
    function testGetSpecificTokenConfig() public view {
        console.log("==================================================");
        console.log("WETH CONFIGURATION DETAILS");
        console.log("==================================================");
        _displayTokenConfig(WETH, "WETH");
    }

    /**
     * @notice Compare our current config with mainnet
     */
    function testCompareWithMainnet() public view {
        console.log(
            "================================================================================"
        );
        console.log("COMPARISON: OUR CONFIG vs MAINNET");
        console.log(
            "================================================================================"
        );

        // Add comparison logic here if needed
        // This could compare our TokenConfig values with actual mainnet values
    }
}
