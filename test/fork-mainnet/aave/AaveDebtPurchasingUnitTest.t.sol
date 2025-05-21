// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SetUpAave.t.sol";
import "../../../src/aave/AaveRouter.sol";
import "../../../src/aave/AaveDebt.sol";

contract AaveDebtPurchasingUnitTest is SetUpAave {
    AaveRouter public router;

    // Storage variables for test state
    struct DebtState {
        uint256 totalCollateralBase;
        uint256 totalDebtBase;
        uint256 availableBorrowsBase;
        uint256 healthFactor;
        uint256 usdcAmount;
        uint256 usdtAmount;
        uint256 initialVDebtUSDC;
        uint256 initialVDebtUSDT;
        uint256 initialATokenBalance;
        uint256 repayAmount;
    }

    DebtState private debtState;

    function setUp() public override {
        super.setUp();

        AaveDebt aaveDebt = new AaveDebt();

        router = new AaveRouter(
            address(aaveDebt),
            AAVE_V3_POOL_ADDRESSES_PROVIDER
        );
    }

    function test_setUp_succss() public {}

    function testCreateDebt() public {
        // Switch to alice's context
        vm.startPrank(alice);

        // Get predicted address before creation
        address predictedAddress = router.predictDebtAddress(alice);

        // Create debt position
        address debtAddress = router.createDebt();

        // Verify the created address matches the predicted one
        assertEq(debtAddress, predictedAddress, "Debt address mismatch");

        // Verify the debt position is initialized correctly
        assertEq(router.debtOwners(debtAddress), alice, "Wrong debt owner");
        assertEq(router.userNonces(alice), 1, "Wrong user nonce");

        // Verify the debt position is initialized with Aave Pool
        AaveDebt debt = AaveDebt(debtAddress);
        assertEq(address(debt.aavePool()), address(pool), "Wrong Aave Pool");

        vm.stopPrank();
    }

    function testCreateMultipleDebtPositions() public {
        vm.startPrank(alice);

        // Create first debt position
        address debtAddress1 = router.createDebt();
        assertEq(router.userNonces(alice), 1, "Wrong first nonce");

        // Create second debt position
        address debtAddress2 = router.createDebt();
        assertEq(router.userNonces(alice), 2, "Wrong second nonce");

        // Verify different addresses
        assertTrue(
            debtAddress1 != debtAddress2,
            "Debt addresses should be different"
        );

        // Verify both positions are owned by alice
        assertEq(
            router.debtOwners(debtAddress1),
            alice,
            "Wrong first debt owner"
        );
        assertEq(
            router.debtOwners(debtAddress2),
            alice,
            "Wrong second debt owner"
        );

        vm.stopPrank();
    }

    function testCreateDebtFromDifferentUsers() public {
        // Alice creates debt position
        vm.startPrank(alice);
        address aliceDebtAddress = router.createDebt();
        vm.stopPrank();

        // Bob creates debt position
        vm.startPrank(bob);
        address bobDebtAddress = router.createDebt();
        vm.stopPrank();

        // Verify different addresses
        assertTrue(
            aliceDebtAddress != bobDebtAddress,
            "Debt addresses should be different"
        );

        // Verify correct ownership
        assertEq(
            router.debtOwners(aliceDebtAddress),
            alice,
            "Wrong Alice's debt owner"
        );
        assertEq(
            router.debtOwners(bobDebtAddress),
            bob,
            "Wrong Bob's debt owner"
        );

        // Verify correct nonces
        assertEq(router.userNonces(alice), 1, "Wrong Alice's nonce");
        assertEq(router.userNonces(bob), 1, "Wrong Bob's nonce");
    }

    function testPredictDebtAddress() public {
        vm.startPrank(alice);

        // Get predicted address
        address predictedAddress = router.predictDebtAddress(alice);

        // Create debt position
        address actualAddress = router.createDebt();

        // Verify prediction was correct
        assertEq(actualAddress, predictedAddress, "Predicted address mismatch");

        // Verify prediction for next position
        address nextPredictedAddress = router.predictDebtAddress(alice);
        address nextActualAddress = router.createDebt();
        assertEq(
            nextActualAddress,
            nextPredictedAddress,
            "Next predicted address mismatch"
        );

        vm.stopPrank();
    }

    function testTransferDebtOwnership() public {
        // Alice creates a debt position
        vm.startPrank(alice);
        address debtAddress = router.createDebt();
        vm.stopPrank();

        // Verify initial ownership
        assertEq(
            router.debtOwners(debtAddress),
            alice,
            "Initial owner should be Alice"
        );

        // Alice transfers ownership to Bob
        vm.startPrank(alice);
        router.transferDebtOwnership(debtAddress, bob);
        vm.stopPrank();

        // Verify new ownership
        assertEq(
            router.debtOwners(debtAddress),
            bob,
            "New owner should be Bob"
        );
        assertEq(
            router.debtNonces(debtAddress),
            1,
            "Debt nonce should be incremented"
        );
    }

    function testTransferDebtOwnershipFromNonOwner() public {
        // Alice creates a debt position
        vm.startPrank(alice);
        address debtAddress = router.createDebt();
        vm.stopPrank();

        // Bob tries to transfer ownership (should fail)
        vm.startPrank(bob);
        vm.expectRevert("Not owner");
        router.transferDebtOwnership(debtAddress, carol);
        vm.stopPrank();

        // Verify ownership hasn't changed
        assertEq(
            router.debtOwners(debtAddress),
            alice,
            "Owner should still be Alice"
        );
    }

    function testTransferDebtOwnershipToZeroAddress() public {
        // Alice creates a debt position
        vm.startPrank(alice);
        address debtAddress = router.createDebt();
        vm.stopPrank();

        // Alice tries to transfer to zero address
        vm.startPrank(alice);
        router.transferDebtOwnership(debtAddress, address(0));
        vm.stopPrank();

        // Verify ownership has been transferred to zero address
        assertEq(
            router.debtOwners(debtAddress),
            address(0),
            "Owner should be zero address"
        );
        assertEq(
            router.debtNonces(debtAddress),
            1,
            "Debt nonce should be incremented"
        );
    }

    function testTransferDebtOwnershipMultipleTimes() public {
        // Alice creates a debt position
        vm.startPrank(alice);
        address debtAddress = router.createDebt();
        vm.stopPrank();

        // Transfer ownership chain: Alice -> Bob -> Carol -> Daniel
        vm.startPrank(alice);
        router.transferDebtOwnership(debtAddress, bob);
        vm.stopPrank();

        vm.startPrank(bob);
        router.transferDebtOwnership(debtAddress, carol);
        vm.stopPrank();

        vm.startPrank(carol);
        router.transferDebtOwnership(debtAddress, daniel);
        vm.stopPrank();

        // Verify final ownership
        assertEq(
            router.debtOwners(debtAddress),
            daniel,
            "Final owner should be Daniel"
        );
        assertEq(
            router.debtNonces(debtAddress),
            3,
            "Debt nonce should be incremented"
        );
    }

    function testCancelDebtCurrentOrders() public {
        // Alice creates a debt position
        vm.startPrank(alice);
        address debtAddress = router.createDebt();

        // Get initial debt nonce
        uint256 initialNonce = router.debtNonces(debtAddress);

        // Cancel current orders
        router.cancelDebtCurrentOrders(debtAddress);

        // Verify nonce has been incremented
        assertEq(
            router.debtNonces(debtAddress),
            initialNonce + 1,
            "Debt nonce should be incremented"
        );

        vm.stopPrank();
    }

    function testCancelDebtCurrentOrdersFromNonOwner() public {
        // Alice creates a debt position
        vm.startPrank(alice);
        address debtAddress = router.createDebt();
        vm.stopPrank();

        // Bob tries to cancel orders (should fail)
        vm.startPrank(bob);
        vm.expectRevert("Not owner");
        router.cancelDebtCurrentOrders(debtAddress);
        vm.stopPrank();

        // Verify nonce hasn't changed
        assertEq(
            router.debtNonces(debtAddress),
            0,
            "Debt nonce should not change"
        );
    }

    function testCancelDebtCurrentOrdersMultipleTimes() public {
        // Alice creates a debt position
        vm.startPrank(alice);
        address debtAddress = router.createDebt();

        // Cancel orders multiple times
        for (uint256 i = 0; i < 3; i++) {
            uint256 currentNonce = router.debtNonces(debtAddress);
            router.cancelDebtCurrentOrders(debtAddress);
            assertEq(
                router.debtNonces(debtAddress),
                currentNonce + 1,
                "Debt nonce should increment each time"
            );
        }

        vm.stopPrank();
    }

    function testCancelDebtCurrentOrdersAfterTransfer() public {
        // Alice creates a debt position
        vm.startPrank(alice);
        address debtAddress = router.createDebt();

        // Transfer ownership to Bob
        router.transferDebtOwnership(debtAddress, bob);
        vm.stopPrank();

        // Bob cancels orders
        vm.startPrank(bob);
        router.cancelDebtCurrentOrders(debtAddress);
        vm.stopPrank();

        // Verify nonce has been incremented
        assertEq(
            router.debtNonces(debtAddress),
            2,
            "Debt nonce should be incremented"
        );
    }

    function testCallSupply() public {
        // Create debt position first
        vm.startPrank(alice);
        address debtAddress = router.createDebt();

        // Get initial collateral
        (uint256 totalCollateralBase, , , , , ) = pool.getUserAccountData(
            debtAddress
        );

        // Supply WETH as collateral
        uint256 supplyAmount = 1 ether;
        weth.approve(address(router), supplyAmount);
        router.callSupply(debtAddress, WETH, supplyAmount);

        // Get updated collateral
        (uint256 newTotalCollateralBase, , , , , ) = pool.getUserAccountData(
            debtAddress
        );

        // Verify collateral was supplied
        assertEq(
            newTotalCollateralBase,
            totalCollateralBase +
                (supplyAmount * priceOracle.getAssetPrice(WETH)) /
                1e18,
            "Total collateral should increase"
        );

        // Verify aToken balance
        address aTokenAddress = pool.getReserveData(WETH).aTokenAddress;
        assertEq(
            IERC20(aTokenAddress).balanceOf(debtAddress),
            supplyAmount,
            "aToken balance should match supply amount"
        );

        vm.stopPrank();
    }

    function testCallSupplyMultipleAssets() public {
        vm.startPrank(alice);
        address debtAddress = router.createDebt();

        // Supply WETH
        uint256 wethAmount = 1 ether;
        weth.approve(address(router), wethAmount);
        router.callSupply(debtAddress, WETH, wethAmount);

        // Supply WBTC
        uint256 wbtcAmount = 0.1 * 1e8; // 0.1 WBTC
        wbtc.approve(address(router), wbtcAmount);
        router.callSupply(debtAddress, WBTC, wbtcAmount);

        // Get user data
        (uint256 totalCollateralBase, , , , , ) = pool.getUserAccountData(
            debtAddress
        );

        // Calculate expected collateral value
        uint256 expectedWethValue = (wethAmount *
            priceOracle.getAssetPrice(WETH)) / 1e18;
        uint256 expectedWbtcValue = (wbtcAmount *
            priceOracle.getAssetPrice(WBTC)) / 1e8;
        uint256 expectedTotalCollateral = expectedWethValue + expectedWbtcValue;

        // Verify total collateral
        assertEq(
            totalCollateralBase,
            expectedTotalCollateral,
            "Total collateral should match sum of supplied assets"
        );

        // Verify aToken balances
        address aWethAddress = pool.getReserveData(WETH).aTokenAddress;
        address aWbtcAddress = pool.getReserveData(WBTC).aTokenAddress;

        assertEq(
            IERC20(aWethAddress).balanceOf(debtAddress),
            wethAmount,
            "aWETH balance should match supply amount"
        );
        assertEq(
            IERC20(aWbtcAddress).balanceOf(debtAddress),
            wbtcAmount,
            "aWBTC balance should match supply amount"
        );

        vm.stopPrank();
    }

    function testCallSupplyWithInsufficientAllowance() public {
        vm.startPrank(alice);
        address debtAddress = router.createDebt();

        // Try to supply without approval
        uint256 supplyAmount = 1 ether;
        vm.expectRevert("SafeERC20: low-level call failed");
        router.callSupply(debtAddress, WETH, supplyAmount);

        vm.stopPrank();
    }

    function testCallSupplyWithInsufficientBalance() public {
        vm.startPrank(alice);
        address debtAddress = router.createDebt();

        // Try to supply more than balance
        uint256 supplyAmount = type(uint256).max;
        weth.approve(address(router), supplyAmount);
        vm.expectRevert("SafeERC20: low-level call failed");
        router.callSupply(debtAddress, WETH, supplyAmount);

        vm.stopPrank();
    }

    function _getUserAccountData(
        address user
    )
        internal
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 healthFactor
        )
    {
        (
            totalCollateralBase,
            totalDebtBase,
            availableBorrowsBase,
            ,
            ,
            healthFactor
        ) = pool.getUserAccountData(user);
    }

    function _logAccountState(
        string memory label,
        uint256 collateral,
        uint256 debt,
        uint256 availableBorrows,
        uint256 healthFactor
    ) internal pure {
        console.log(string.concat("\n", label, ":"));
        console.log("Total Collateral:", collateral);
        console.log("Total Debt:", debt);
        console.log("Available Borrows:", availableBorrows);
        console.log("Health Factor:", healthFactor);
    }

    function _setupBorrowTest(
        address sender,
        address[] memory assets,
        uint256[] memory amounts
    ) internal returns (address) {
        require(assets.length == amounts.length, "Arrays length mismatch");

        vm.startPrank(sender);
        address debtAddress = router.createDebt();

        // Supply assets as collateral
        for (uint256 i = 0; i < assets.length; i++) {
            IERC20(assets[i]).approve(address(router), amounts[i]);
            router.callSupply(debtAddress, assets[i], amounts[i]);
        }

        vm.stopPrank();
        return debtAddress;
    }

    function _calculateBorrowAmounts(
        uint256 availableBorrowsBase
    ) internal view returns (uint256 usdcAmount, uint256 usdtAmount) {
        uint256 borrowValue = availableBorrowsBase / 2; // Half of available borrows in USD
        usdcAmount = (borrowValue * 1e6) / priceOracle.getAssetPrice(USDC); // Convert to USDC decimals
        usdtAmount = (borrowValue * 1e6) / priceOracle.getAssetPrice(USDT); // Convert to USDT decimals
    }

    function _verifyBorrowState(
        address debtAddress,
        uint256 expectedUsdcAmount,
        uint256 expectedUsdtAmount
    ) internal view {
        // Verify vDebt balances
        assertEq(
            vDebtUSDC.balanceOf(debtAddress),
            expectedUsdcAmount,
            "vDebtUSDC balance should match borrow amount"
        );
        assertEq(
            vDebtUSDT.balanceOf(debtAddress),
            expectedUsdtAmount,
            "vDebtUSDT balance should match borrow amount"
        );
    }

    function testCallBorrow() public {
        // Setup test with WETH collateral
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = WETH;
        amounts[0] = 1 ether;

        address debtAddress = _setupBorrowTest(alice, assets, amounts);

        // Get initial debt
        (, uint256 totalDebtBase, , ) = _getUserAccountData(debtAddress);

        // Borrow USDC
        uint256 borrowAmount = 1000 * 1e6; // 1000 USDC
        vm.startPrank(alice);
        router.callBorrow(debtAddress, USDC, borrowAmount, 2);

        // Get updated debt
        (, uint256 newTotalDebtBase, , ) = _getUserAccountData(debtAddress);

        // Verify debt increased
        assertEq(
            newTotalDebtBase,
            totalDebtBase +
                (borrowAmount * priceOracle.getAssetPrice(USDC)) /
                1e6,
            "Total debt should increase"
        );

        // Verify vDebt balance
        assertEq(
            vDebtUSDC.balanceOf(debtAddress),
            borrowAmount,
            "vDebtUSDC balance should match borrow amount"
        );

        vm.stopPrank();
    }

    function testCallBorrowMultipleAssets() public {
        // Setup test with WETH collateral
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = WETH;
        amounts[0] = 1 ether;

        address debtAddress = _setupBorrowTest(alice, assets, amounts);

        // Get initial state
        (
            debtState.totalCollateralBase,
            debtState.totalDebtBase,
            debtState.availableBorrowsBase,
            debtState.healthFactor
        ) = _getUserAccountData(debtAddress);

        _logAccountState(
            "Initial State",
            debtState.totalCollateralBase,
            debtState.totalDebtBase,
            debtState.availableBorrowsBase,
            debtState.healthFactor
        );

        // Calculate borrow amounts
        (debtState.usdcAmount, debtState.usdtAmount) = _calculateBorrowAmounts(
            debtState.availableBorrowsBase
        );

        console.log("\nBorrow Amounts:");
        console.log("USDC Amount:", debtState.usdcAmount);
        console.log("USDT Amount:", debtState.usdtAmount);

        // Start prank for borrow operations
        vm.startPrank(alice);

        // Borrow USDC
        router.callBorrow(debtAddress, USDC, debtState.usdcAmount, 2);

        // Get intermediate state
        (
            uint256 midCollateralBase,
            uint256 midDebtBase,
            uint256 midAvailableBorrowsBase,
            uint256 midHealthFactor
        ) = _getUserAccountData(debtAddress);

        // Verify USDC debt increased
        assertEq(
            midDebtBase,
            debtState.totalDebtBase +
                (debtState.usdcAmount * priceOracle.getAssetPrice(USDC)) /
                1e6,
            "Total debt should increase after USDC borrow"
        );

        _logAccountState(
            "After USDC Borrow",
            midCollateralBase,
            midDebtBase,
            midAvailableBorrowsBase,
            midHealthFactor
        );

        // Borrow USDT
        router.callBorrow(debtAddress, USDT, debtState.usdtAmount, 2);

        // Get final state
        (
            uint256 finalCollateralBase,
            uint256 finalDebtBase,
            uint256 finalAvailableBorrowsBase,
            uint256 finalHealthFactor
        ) = _getUserAccountData(debtAddress);

        // Verify total debt increased by both borrows
        assertEq(
            finalDebtBase,
            debtState.totalDebtBase +
                (debtState.usdcAmount * priceOracle.getAssetPrice(USDC)) /
                1e6 +
                (debtState.usdtAmount * priceOracle.getAssetPrice(USDT)) /
                1e6,
            "Total debt should increase by both borrows"
        );

        _logAccountState(
            "After USDT Borrow",
            finalCollateralBase,
            finalDebtBase,
            finalAvailableBorrowsBase,
            finalHealthFactor
        );

        // Verify states
        assertEq(
            finalCollateralBase,
            debtState.totalCollateralBase,
            "Collateral should not change"
        );
        assertTrue(
            finalDebtBase > debtState.totalDebtBase,
            "Total debt should increase"
        );
        assertTrue(
            finalAvailableBorrowsBase < debtState.availableBorrowsBase,
            "Available borrows should decrease"
        );
        assertTrue(finalHealthFactor > 1e18, "Health factor should be safe");

        // Verify borrow amounts
        _verifyBorrowState(
            debtAddress,
            debtState.usdcAmount,
            debtState.usdtAmount
        );

        vm.stopPrank();
    }

    function testCallBorrowWithInsufficientCollateral() public {
        vm.startPrank(alice);
        address debtAddress = router.createDebt();

        // Supply small amount of WETH
        uint256 supplyAmount = 0.1 ether;
        weth.approve(address(router), supplyAmount);
        router.callSupply(debtAddress, WETH, supplyAmount);

        // Try to borrow large amount (should fail)
        uint256 borrowAmount = 1000000 * 1e6; // 1M USDC
        vm.expectRevert();
        router.callBorrow(debtAddress, USDC, borrowAmount, 2);

        vm.stopPrank();
    }

    function testCallBorrowFromNonOwner() public {
        // Alice creates debt position and supplies collateral
        vm.startPrank(alice);
        address debtAddress = router.createDebt();
        uint256 supplyAmount = 1 ether;
        weth.approve(address(router), supplyAmount);
        router.callSupply(debtAddress, WETH, supplyAmount);
        vm.stopPrank();

        // Bob tries to borrow (should fail)
        vm.startPrank(bob);
        uint256 borrowAmount = 1000 * 1e6;
        vm.expectRevert("Not owner");
        router.callBorrow(debtAddress, USDC, borrowAmount, 2);
        vm.stopPrank();
    }

    function _verifyWithdrawState(
        address debtAddress,
        uint256 expectedWethBalance,
        uint256 expectedWbtcBalance,
        uint256 expectedCollateral
    ) internal view {
        // Get aToken addresses
        address aWethAddress = pool.getReserveData(WETH).aTokenAddress;
        address aWbtcAddress = pool.getReserveData(WBTC).aTokenAddress;

        // Get actual balances
        uint256 actualWethBalance = IERC20(aWethAddress).balanceOf(debtAddress);
        uint256 actualWbtcBalance = IERC20(aWbtcAddress).balanceOf(debtAddress);

        // Verify aToken balances with 1 wei tolerance
        assertApproxEqAbs(
            actualWethBalance,
            expectedWethBalance,
            1,
            "aWETH balance should approximately match expected"
        );
        assertApproxEqAbs(
            actualWbtcBalance,
            expectedWbtcBalance,
            1,
            "aWBTC balance should approximately match expected"
        );

        // Get current state
        (
            uint256 currentCollateralBase,
            uint256 currentDebtBase,
            ,
            uint256 currentHealthFactor
        ) = _getUserAccountData(debtAddress);

        // Verify collateral with 1% tolerance
        uint256 tolerance = expectedCollateral / 100; // 1% tolerance
        assertApproxEqAbs(
            currentCollateralBase,
            expectedCollateral,
            tolerance,
            "Total collateral should approximately match expected"
        );

        // Verify debt unchanged
        assertEq(
            currentDebtBase,
            debtState.totalDebtBase,
            "Total debt should remain unchanged"
        );

        // Verify health factor
        assertTrue(
            currentHealthFactor > 1e18,
            "Health factor should remain safe"
        );
    }

    function testCallWithdraw() public {
        // Setup test with WETH collateral
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = WETH;
        amounts[0] = 1 ether;

        address debtAddress = _setupBorrowTest(alice, assets, amounts);

        // Get initial state
        (
            ,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,

        ) = _getUserAccountData(debtAddress);

        // Get initial aToken balance
        address aTokenAddress = pool.getReserveData(WETH).aTokenAddress;
        uint256 initialATokenBalance = IERC20(aTokenAddress).balanceOf(
            debtAddress
        );

        // Withdraw half of the collateral
        uint256 withdrawAmount = amounts[0] / 2;
        vm.startPrank(alice);
        router.callWithdraw(debtAddress, WETH, withdrawAmount, alice);

        // Get final state
        (
            uint256 newTotalCollateralBase,
            uint256 newTotalDebtBase,
            uint256 newAvailableBorrowsBase,
            uint256 newHealthFactor
        ) = _getUserAccountData(debtAddress);

        // Get final aToken balance
        uint256 finalATokenBalance = IERC20(aTokenAddress).balanceOf(
            debtAddress
        );

        // Calculate expected collateral:
        // 1. Calculate remaining ETH after withdrawal
        uint256 remainingEth = initialATokenBalance - withdrawAmount;
        // 2. Convert remaining ETH to base value using price oracle
        uint256 expectedCollateral = (remainingEth *
            priceOracle.getAssetPrice(WETH)) / 1e18;

        // Verify collateral decreased
        assertEq(
            newTotalCollateralBase,
            expectedCollateral,
            "Total collateral should match remaining ETH value"
        );

        // Verify aToken balance decreased with 1 wei tolerance
        assertApproxEqAbs(
            finalATokenBalance,
            initialATokenBalance - withdrawAmount,
            1,
            "aToken balance should approximately decrease"
        );

        // Verify debt remains unchanged
        assertEq(
            newTotalDebtBase,
            totalDebtBase,
            "Total debt should remain unchanged"
        );

        // Verify available borrows decreased
        assertTrue(
            newAvailableBorrowsBase < availableBorrowsBase,
            "Available borrows should decrease"
        );

        // Verify health factor remains safe
        assertTrue(newHealthFactor > 1e18, "Health factor should remain safe");

        vm.stopPrank();
    }

    function testCallWithdrawMultipleAssets() public {
        // Setup test with WETH and WBTC collateral
        address[] memory assets = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        assets[0] = WETH;
        amounts[0] = 1 ether;
        assets[1] = WBTC;
        amounts[1] = 0.1 * 1e8; // 0.1 WBTC

        address debtAddress = _setupBorrowTest(alice, assets, amounts);

        // Get initial state
        (
            debtState.totalCollateralBase,
            debtState.totalDebtBase,
            debtState.availableBorrowsBase,
            debtState.healthFactor
        ) = _getUserAccountData(debtAddress);

        // Get initial aToken balances
        address aWethAddress = pool.getReserveData(WETH).aTokenAddress;
        address aWbtcAddress = pool.getReserveData(WBTC).aTokenAddress;
        debtState.initialATokenBalance = IERC20(aWethAddress).balanceOf(
            debtAddress
        );
        debtState.initialVDebtUSDT = IERC20(aWbtcAddress).balanceOf(
            debtAddress
        );

        // Calculate withdraw amounts
        uint256 withdrawWethAmount = amounts[0] / 2;
        uint256 withdrawWbtcAmount = amounts[1] / 2;

        vm.startPrank(alice);

        // Withdraw WETH
        router.callWithdraw(debtAddress, WETH, withdrawWethAmount, alice);

        // Calculate expected collateral after WETH withdrawal
        uint256 expectedCollateralAfterWeth = debtState.totalCollateralBase -
            (withdrawWethAmount * priceOracle.getAssetPrice(WETH)) /
            1e18;

        // Verify state after WETH withdrawal
        _verifyWithdrawState(
            debtAddress,
            debtState.initialATokenBalance - withdrawWethAmount,
            debtState.initialVDebtUSDT,
            expectedCollateralAfterWeth
        );

        // Withdraw WBTC
        router.callWithdraw(debtAddress, WBTC, withdrawWbtcAmount, alice);

        // Calculate expected collateral after both withdrawals
        uint256 expectedFinalCollateral = expectedCollateralAfterWeth -
            (withdrawWbtcAmount * priceOracle.getAssetPrice(WBTC)) /
            1e8;

        // Verify final state
        _verifyWithdrawState(
            debtAddress,
            debtState.initialATokenBalance - withdrawWethAmount,
            debtState.initialVDebtUSDT - withdrawWbtcAmount,
            expectedFinalCollateral
        );

        vm.stopPrank();
    }

    function testCallWithdrawFromNonOwner() public {
        // Setup test with WETH collateral
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = WETH;
        amounts[0] = 1 ether;

        address debtAddress = _setupBorrowTest(alice, assets, amounts);

        // Bob tries to withdraw (should fail)
        vm.startPrank(bob);
        vm.expectRevert("Not owner");
        router.callWithdraw(debtAddress, WETH, amounts[0] / 2, bob);
        vm.stopPrank();
    }

    function testCallWithdrawWithInsufficientBalance() public {
        // Setup test with WETH collateral
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = WETH;
        amounts[0] = 1 ether;

        address debtAddress = _setupBorrowTest(alice, assets, amounts);

        // Try to withdraw more than balance
        vm.startPrank(alice);
        vm.expectRevert();
        router.callWithdraw(debtAddress, WETH, amounts[0] * 2, alice);
        vm.stopPrank();
    }

    function testCallWithdrawWithUnsafeHealthFactor() public {
        // Setup test with WETH collateral
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = WETH;
        amounts[0] = 1 ether;

        address debtAddress = _setupBorrowTest(alice, assets, amounts);

        // Borrow maximum amount
        (, , uint256 availableBorrowsBase, ) = _getUserAccountData(debtAddress);

        uint256 borrowAmount = (availableBorrowsBase * 1e6) /
            priceOracle.getAssetPrice(USDC);

        vm.startPrank(alice);
        router.callBorrow(debtAddress, USDC, borrowAmount, 2);

        // Try to withdraw (should fail due to unsafe health factor)
        vm.expectRevert();
        router.callWithdraw(debtAddress, WETH, amounts[0] / 2, alice);
        vm.stopPrank();
    }

    function _verifyRepayState(
        address debtAddress,
        uint256 expectedVDebtBalance,
        uint256 expectedCollateral,
        uint256 expectedDebt
    ) internal view {
        // Get current state
        (
            uint256 currentCollateralBase,
            uint256 currentDebtBase,
            uint256 currentAvailableBorrowsBase,
            uint256 currentHealthFactor
        ) = _getUserAccountData(debtAddress);

        // Verify collateral
        assertEq(
            currentCollateralBase,
            expectedCollateral,
            "Total collateral should match expected"
        );

        // Verify debt
        assertEq(
            currentDebtBase,
            expectedDebt,
            "Total debt should match expected"
        );

        // Verify vDebt balance
        assertEq(
            vDebtUSDC.balanceOf(debtAddress),
            expectedVDebtBalance,
            "vDebt balance should match expected"
        );

        // Verify health factor
        assertTrue(
            currentHealthFactor > 1e18,
            "Health factor should remain safe"
        );
    }

    function testCallRepay() public {
        // Setup test with WETH collateral and USDC debt
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = WETH;
        amounts[0] = 1 ether;

        address debtAddress = _setupBorrowTest(alice, assets, amounts);

        // Borrow USDC
        uint256 borrowAmount = 1000 * 1e6; // 1000 USDC
        vm.startPrank(alice);
        router.callBorrow(debtAddress, USDC, borrowAmount, 2);

        // Get initial state
        (
            debtState.totalCollateralBase,
            debtState.totalDebtBase,
            debtState.availableBorrowsBase,
            debtState.healthFactor
        ) = _getUserAccountData(debtAddress);

        // Get initial vDebt balance
        debtState.initialVDebtUSDC = vDebtUSDC.balanceOf(debtAddress);

        // Repay half of the debt
        debtState.repayAmount = borrowAmount / 2;
        usdc.approve(address(router), debtState.repayAmount);
        router.callRepay(debtAddress, USDC, debtState.repayAmount, 2);

        // Calculate expected values with 1 wei tolerance
        uint256 expectedVDebtBalance = debtState.initialVDebtUSDC -
            debtState.repayAmount;
        uint256 expectedDebt = debtState.totalDebtBase -
            (debtState.repayAmount * priceOracle.getAssetPrice(USDC)) /
            1e6;

        // Verify state with 1 wei tolerance
        assertApproxEqAbs(
            vDebtUSDC.balanceOf(debtAddress),
            expectedVDebtBalance,
            1,
            "vDebt balance should match expected"
        );

        (
            uint256 currentCollateralBase,
            uint256 currentDebtBase,
            ,
            uint256 currentHealthFactor
        ) = _getUserAccountData(debtAddress);

        assertEq(
            currentCollateralBase,
            debtState.totalCollateralBase,
            "Total collateral should remain unchanged"
        );

        assertApproxEqAbs(
            currentDebtBase,
            expectedDebt,
            1000,
            "Total debt should match expected"
        );

        assertTrue(
            currentHealthFactor > 1e18,
            "Health factor should remain safe"
        );

        vm.stopPrank();
    }

    function testCallRepayMultipleAssets() public {
        // Setup test with WETH collateral
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = WETH;
        amounts[0] = 1 ether;

        address debtAddress = _setupBorrowTest(alice, assets, amounts);

        // Borrow USDC and USDT
        uint256 borrowUSDC = 500 * 1e6; // 500 USDC
        uint256 borrowUSDT = 500 * 1e6; // 500 USDT

        vm.startPrank(alice);
        router.callBorrow(debtAddress, USDC, borrowUSDC, 2);
        router.callBorrow(debtAddress, USDT, borrowUSDT, 2);

        // Get initial state
        (
            debtState.totalCollateralBase,
            debtState.totalDebtBase,
            debtState.availableBorrowsBase,
            debtState.healthFactor
        ) = _getUserAccountData(debtAddress);

        // Get initial vDebt balances
        debtState.initialVDebtUSDC = vDebtUSDC.balanceOf(debtAddress);
        debtState.initialVDebtUSDT = vDebtUSDT.balanceOf(debtAddress);

        // Repay half of each debt
        debtState.usdcAmount = borrowUSDC / 2;
        debtState.usdtAmount = borrowUSDT / 2;

        // Repay USDC
        usdc.approve(address(router), debtState.usdcAmount);
        router.callRepay(debtAddress, USDC, debtState.usdcAmount, 2);

        // Calculate expected values after USDC repay
        uint256 expectedVDebtUSDC = debtState.initialVDebtUSDC -
            debtState.usdcAmount;
        uint256 expectedDebtAfterUSDC = debtState.totalDebtBase -
            (debtState.usdcAmount * priceOracle.getAssetPrice(USDC)) /
            1e6;

        // Verify state after USDC repay
        assertApproxEqAbs(
            vDebtUSDC.balanceOf(debtAddress),
            expectedVDebtUSDC,
            1,
            "vDebtUSDC balance should match expected"
        );

        (
            uint256 currentCollateralBase,
            uint256 currentDebtBase,
            ,
            uint256 currentHealthFactor
        ) = _getUserAccountData(debtAddress);

        assertEq(
            currentCollateralBase,
            debtState.totalCollateralBase,
            "Total collateral should remain unchanged"
        );

        assertApproxEqAbs(
            currentDebtBase,
            expectedDebtAfterUSDC,
            1000,
            "Total debt should match expected after USDC repay"
        );

        // Repay USDT
        usdt.approve(address(router), debtState.usdtAmount);
        router.callRepay(debtAddress, USDT, debtState.usdtAmount, 2);

        // Calculate expected values after both repays
        uint256 expectedVDebtUSDT = debtState.initialVDebtUSDT -
            debtState.usdtAmount;
        uint256 expectedFinalDebt = expectedDebtAfterUSDC -
            (debtState.usdtAmount * priceOracle.getAssetPrice(USDT)) /
            1e6;

        // Verify final state
        assertApproxEqAbs(
            vDebtUSDT.balanceOf(debtAddress),
            expectedVDebtUSDT,
            1,
            "vDebtUSDT balance should match expected"
        );

        (
            currentCollateralBase,
            currentDebtBase,
            ,
            currentHealthFactor
        ) = _getUserAccountData(debtAddress);

        assertEq(
            currentCollateralBase,
            debtState.totalCollateralBase,
            "Total collateral should remain unchanged"
        );

        assertApproxEqAbs(
            currentDebtBase,
            expectedFinalDebt,
            1,
            "Total debt should match expected after both repays"
        );

        assertTrue(
            currentHealthFactor > 1e18,
            "Health factor should remain safe"
        );

        vm.stopPrank();
    }

    function testCallRepayWithInsufficientBalance() public {
        // Setup test with WETH collateral and USDC debt
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = WETH;
        amounts[0] = 1 ether;

        address debtAddress = _setupBorrowTest(alice, assets, amounts);

        // Borrow USDC
        uint256 borrowAmount = 1000 * 1e6; // 1000 USDC
        vm.startPrank(alice);
        router.callBorrow(debtAddress, USDC, borrowAmount, 2);
        vm.stopPrank();

        // Create new account without USDC
        address newUser = makeAddr("newUser");
        vm.startPrank(newUser);
        
        // Try to repay without having USDC
        uint256 repayAmount = borrowAmount / 2;
        vm.expectRevert("SafeERC20: low-level call failed");
        router.callRepay(debtAddress, USDC, repayAmount, 2);
        vm.stopPrank();
    }

    function testCallRepayWithATokens() public {
        // Setup test with WETH collateral and USDC debt
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        assets[0] = WETH;
        amounts[0] = 1 ether;

        address debtAddress = _setupBorrowTest(alice, assets, amounts);

        // Supply USDC to get aUSDC
        uint256 supplyAmount = 2000 * 1e6; // 2000 USDC
        vm.startPrank(alice);
        usdc.approve(address(router), supplyAmount);
        router.callSupply(debtAddress, USDC, supplyAmount);

        // Borrow USDC
        uint256 borrowAmount = 1000 * 1e6; // 1000 USDC
        router.callBorrow(debtAddress, USDC, borrowAmount, 2);

        // Get initial state
        (
            debtState.totalCollateralBase,
            debtState.totalDebtBase,
            debtState.availableBorrowsBase,
            debtState.healthFactor
        ) = _getUserAccountData(debtAddress);

        // Get initial vDebt balance
        debtState.initialVDebtUSDC = vDebtUSDC.balanceOf(debtAddress);

        // Get aUSDC balance
        address aUSDC = pool.getReserveData(USDC).aTokenAddress;
        debtState.initialATokenBalance = IERC20(aUSDC).balanceOf(debtAddress);

        // Repay half of the debt using aTokens
        debtState.repayAmount = borrowAmount / 2;
        IERC20(aUSDC).approve(address(router), debtState.repayAmount);
        router.callRepayWithATokens(debtAddress, USDC, debtState.repayAmount, 2);

        // Calculate expected values
        uint256 expectedVDebtBalance = debtState.initialVDebtUSDC - debtState.repayAmount;
        uint256 expectedDebt = debtState.totalDebtBase -
            (debtState.repayAmount * priceOracle.getAssetPrice(USDC)) /
            1e6;

        // Verify state
        assertApproxEqAbs(
            vDebtUSDC.balanceOf(debtAddress),
            expectedVDebtBalance,
            1,
            "vDebt balance should match expected"
        );

        (
            uint256 currentCollateralBase,
            uint256 currentDebtBase,
            ,
            uint256 currentHealthFactor
        ) = _getUserAccountData(debtAddress);

        assertEq(
            currentCollateralBase,
            debtState.totalCollateralBase,
            "Total collateral should remain unchanged"
        );

        assertApproxEqAbs(
            currentDebtBase,
            expectedDebt,
            1000,
            "Total debt should match expected"
        );

        assertTrue(
            currentHealthFactor > 1e18,
            "Health factor should remain safe"
        );

        vm.stopPrank();
    }
}
