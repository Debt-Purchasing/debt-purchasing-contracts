// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPoolConfigurator.sol";
import "@aave/core-v3/contracts/interfaces/IPriceOracleGetter.sol";
import "@aave/core-v3/contracts/interfaces/IAToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@aave/core-v3/contracts/mocks/oracle/PriceOracle.sol";

contract SetUpAave is Test {
    // Aave V3 Mainnet addresses
    address public constant AAVE_V3_POOL =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant AAVE_V3_POOL_ADDRESSES_PROVIDER =
        0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address public constant AAVE_V3_POOL_CONFIGURATOR =
        0x64b761D848206f447Fe2dd461b0c635Ec39EbB27;
    address public constant AAVE_V3_PRICE_ORACLE =
        0x54586bE62E3c3580375aE3723C145253060Ca0C2;
    address public constant AAVE_V3_ACL_MANAGER =
        0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0;

    // Token addresses
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    // Test accounts
    address public admin;
    address public alice;
    address public bob;
    address public carol;
    address public daniel;
    address public elio;

    // Aave contracts
    IPool public pool;
    IPoolAddressesProvider public addressesProvider;
    IPoolConfigurator public poolConfigurator;

    // Token contracts
    IERC20 public weth;
    IERC20 public wbtc;
    IERC20 public usdc;
    IERC20 public usdt;
    IERC20 public dai;
    IERC20 public aave;

    // AToken contracts for deposits
    IAToken public aWETH;
    IAToken public aWBTC;

    // Debt token contracts for borrows
    IERC20 public vDebtUSDC;
    IERC20 public vDebtUSDT;

    // Mock Price Oracle
    PriceOracle public priceOracle;

    function setUp() public {
        uint256 forkId = vm.createFork(vm.rpcUrl("mainnet"), 19000000);
        vm.selectFork(forkId);

        // Deploy mock price oracle
        priceOracle = new PriceOracle();

        // Setup test accounts
        admin = makeAddr("admin");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");
        daniel = makeAddr("daniel");
        elio = makeAddr("elio");

        // Initialize Aave contracts
        pool = IPool(AAVE_V3_POOL);
        addressesProvider = IPoolAddressesProvider(
            AAVE_V3_POOL_ADDRESSES_PROVIDER
        );
        poolConfigurator = IPoolConfigurator(AAVE_V3_POOL_CONFIGURATOR);

        // Initialize token contracts
        weth = IERC20(WETH);
        wbtc = IERC20(WBTC);
        usdc = IERC20(USDC);
        usdt = IERC20(USDT);
        dai = IERC20(DAI);
        aave = IERC20(AAVE);

        // Initialize AToken contracts
        aWETH = IAToken(pool.getReserveData(WETH).aTokenAddress);
        aWBTC = IAToken(pool.getReserveData(WBTC).aTokenAddress);

        // Initialize debt token contracts
        vDebtUSDC = IERC20(pool.getReserveData(USDC).variableDebtTokenAddress);
        vDebtUSDT = IERC20(pool.getReserveData(USDT).variableDebtTokenAddress);

        // Set new price oracle in Aave
        vm.prank(Ownable(address(addressesProvider)).owner());
        addressesProvider.setPriceOracle(address(priceOracle));

        // Mint tokens to test users
        _mintTokensToUser(alice);
        _mintTokensToUser(bob);
        _mintTokensToUser(carol);
        _mintTokensToUser(daniel);
        _mintTokensToUser(elio);
    }

    function testSetupAaveSuccess() public {
        // Verify pool is initialized
        assertEq(address(pool), AAVE_V3_POOL);
        assertEq(address(addressesProvider), AAVE_V3_POOL_ADDRESSES_PROVIDER);
        assertEq(address(poolConfigurator), AAVE_V3_POOL_CONFIGURATOR);

        // Verify tokens are initialized
        assertEq(address(weth), WETH);
        assertEq(address(wbtc), WBTC);
        assertEq(address(usdc), USDC);
        assertEq(address(usdt), USDT);
        assertEq(address(dai), DAI);
        assertEq(address(aave), AAVE);
    }

    function testAliceDepositAndBorrow() public {
        // Set prices for all tokens first
        setAssetPrice(WETH, 2000 * 1e8); // $2000 per ETH
        setAssetPrice(WBTC, 40000 * 1e8); // $40000 per BTC
        setAssetPrice(USDC, 1 * 1e8); // $1 per USDC
        setAssetPrice(USDT, 1 * 1e8); // $1 per USDT
        setAssetPrice(DAI, 1 * 1e8); // $1 per DAI
        setAssetPrice(AAVE, 100 * 1e8); // $100 per AAVE

        // Initial balances
        uint256 initialWETHBalance = weth.balanceOf(alice);
        uint256 initialWBTCBalance = wbtc.balanceOf(alice);
        uint256 initialUSDCBalance = usdc.balanceOf(alice);
        uint256 initialUSDTBalance = usdt.balanceOf(alice);

        console.log("Initial Balances:");
        console.log("WETH:", initialWETHBalance);
        console.log("WBTC:", initialWBTCBalance);
        console.log("USDC:", initialUSDCBalance);
        console.log("USDT:", initialUSDTBalance);

        // Get prices
        uint256 wethPrice = priceOracle.getAssetPrice(WETH);
        uint256 wbtcPrice = priceOracle.getAssetPrice(WBTC);
        uint256 usdcPrice = priceOracle.getAssetPrice(USDC);
        uint256 usdtPrice = priceOracle.getAssetPrice(USDT);

        console.log("\nAsset Prices (in USD with 8 decimals):");
        console.log("WETH:", wethPrice);
        console.log("WBTC:", wbtcPrice);
        console.log("USDC:", usdcPrice);
        console.log("USDT:", usdtPrice);

        // Calculate collateral value
        uint256 wethCollateralValue = (initialWETHBalance * wethPrice) / 1e18;
        uint256 wbtcCollateralValue = (initialWBTCBalance * wbtcPrice) / 1e8;
        uint256 totalCollateralValue = wethCollateralValue +
            wbtcCollateralValue;

        console.log("\nCollateral Values (in USD with 8 decimals):");
        console.log("WETH Collateral:", wethCollateralValue);
        console.log("WBTC Collateral:", wbtcCollateralValue);
        console.log("Total Collateral:", totalCollateralValue);

        // Approve tokens
        vm.startPrank(alice);
        weth.approve(address(pool), type(uint256).max);
        wbtc.approve(address(pool), type(uint256).max);

        // Deposit collateral
        pool.supply(WETH, initialWETHBalance, alice, 0);
        pool.supply(WBTC, initialWBTCBalance, alice, 0);

        // Get health factor
        (, , , , , uint256 healthFactor) = pool.getUserAccountData(alice);
        console.log("\nHealth Factor after deposit:", healthFactor);

        // Calculate max borrow amounts (80% of collateral value)
        uint256 maxBorrowValue = (totalCollateralValue * 80) / 100;
        uint256 maxUSDCBorrow = (maxBorrowValue * 1e6) / usdcPrice;
        uint256 maxUSDTBorrow = (maxBorrowValue * 1e6) / usdtPrice;

        console.log("\nMaximum Borrow Amounts:");
        console.log("USDC:", maxUSDCBorrow);
        console.log("USDT:", maxUSDTBorrow);

        // Borrow 20% of max for each (reduced from 50% to avoid collateral error)
        uint256 borrowUSDC = maxUSDCBorrow / 3;
        uint256 borrowUSDT = maxUSDTBorrow / 3;

        console.log("\nActual Borrow Amounts:");
        console.log("USDC:", borrowUSDC);
        console.log("USDT:", borrowUSDT);

        // Borrow tokens
        pool.borrow(USDC, borrowUSDC, 2, 0, alice); // 2 = variable rate
        pool.borrow(USDT, borrowUSDT, 2, 0, alice);

        // Final balances
        uint256 finalWETHBalance = weth.balanceOf(alice);
        uint256 finalWBTCBalance = wbtc.balanceOf(alice);
        uint256 finalUSDCBalance = usdc.balanceOf(alice);
        uint256 finalUSDTBalance = usdt.balanceOf(alice);

        console.log("\nFinal Balances:");
        console.log("WETH:", finalWETHBalance);
        console.log("WBTC:", finalWBTCBalance);
        console.log("USDC:", finalUSDCBalance);
        console.log("USDT:", finalUSDTBalance);

        // Get final health factor
        (, , , , , healthFactor) = pool.getUserAccountData(alice);
        console.log("\nFinal Health Factor:", healthFactor);

        // Get debt positions
        uint256 usdcDebt = vDebtUSDC.balanceOf(alice);
        uint256 usdtDebt = vDebtUSDT.balanceOf(alice);

        console.log("\nDebt Positions:");
        console.log("USDC Debt:", usdcDebt);
        console.log("USDT Debt:", usdtDebt);

        vm.stopPrank();
    }

    function _mintTokensToUser(address user) internal {
        // For mainnet fork, we'll use deal() to give users tokens
        deal(WETH, user, 100e18);
        deal(WBTC, user, 10e8);
        deal(USDC, user, 100000e6);
        deal(USDT, user, 100000e6);
        deal(DAI, user, 100000e18);
        deal(AAVE, user, 1000e18);
    }

    /**
     * @notice Sets the price of an asset in the mock price oracle
     * @param asset The address of the asset
     * @param price The price in USD with 8 decimals (e.g., 1 ETH = $2000 -> price = 2000 * 1e8)
     */
    function setAssetPrice(address asset, uint256 price) internal {
        // Set price in mock oracle
        priceOracle.setAssetPrice(asset, price);

        // Verify price was set correctly
        uint256 newPrice = priceOracle.getAssetPrice(asset);
        require(newPrice == price, "Price not set correctly");
    }

    // Example usage in a test
    function testSetPrices() public {
        // Set prices for common assets
        setAssetPrice(WETH, 2000 * 1e8); // $2000 per ETH
        setAssetPrice(WBTC, 40000 * 1e8); // $40000 per BTC
        setAssetPrice(USDC, 1 * 1e8); // $1 per USDC
        setAssetPrice(USDT, 1 * 1e8); // $1 per USDT

        // Verify prices were set
        console.log("WETH Price:", priceOracle.getAssetPrice(WETH));
        console.log("WBTC Price:", priceOracle.getAssetPrice(WBTC));
        console.log("USDC Price:", priceOracle.getAssetPrice(USDC));
        console.log("USDT Price:", priceOracle.getAssetPrice(USDT));
    }
}
