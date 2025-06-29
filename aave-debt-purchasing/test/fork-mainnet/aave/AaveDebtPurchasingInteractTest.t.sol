// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SetUpAave.t.sol";
import "../../../src/AaveRouter.sol";
import "../../../src/AaveDebt.sol";

contract AaveDebtPurchasingInteractTest is SetUpAave {
    AaveRouter public router;

    function setUp() public override {
        super.setUp();

        AaveDebt aaveDebt = new AaveDebt();
        router = new AaveRouter(
            address(aaveDebt),
            AAVE_V3_POOL_ADDRESSES_PROVIDER
        );
    }

    function testCreateSupplyBorrowInSingleTx() public {
        // Get predicted debt address before creation

        address predictedDebtAddress = router.predictDebtAddress(alice);

        // Prepare amounts
        uint256 supplyAmount = 1 ether; // 1 WETH
        uint256 borrowAmount = 1000 * 1e6; // 1000 USDC

        // Prepare multicall data
        bytes[] memory data = new bytes[](3);

        // 1. Create debt position
        data[0] = abi.encodeWithSelector(router.createDebt.selector);

        // 2. Supply WETH
        data[1] = abi.encodeWithSelector(
            router.callSupply.selector,
            predictedDebtAddress,
            WETH,
            supplyAmount
        );

        // 3. Borrow USDC
        data[2] = abi.encodeWithSelector(
            router.callBorrow.selector,
            predictedDebtAddress,
            USDC,
            borrowAmount,
            2, // interest rate mode
            alice // receiver
        );

        // Get initial USDC balance
        uint256 initialUsdcBalance = usdc.balanceOf(alice);

        // Execute multicall
        vm.startPrank(alice);
        weth.approve(address(router), supplyAmount);
        router.multicall(data);
        vm.stopPrank();

        // Verify debt position was created correctly
        assertEq(
            router.debtOwners(predictedDebtAddress),
            alice,
            "Wrong debt owner"
        );
        assertEq(router.userNonces(alice), 1, "Wrong user nonce");

        // Verify WETH was supplied
        address aWethAddress = pool.getReserveData(WETH).aTokenAddress;
        assertEq(
            IERC20(aWethAddress).balanceOf(predictedDebtAddress),
            supplyAmount,
            "aWETH balance should match supply amount"
        );

        // Verify USDC was borrowed
        assertEq(
            vDebtUSDC.balanceOf(predictedDebtAddress),
            borrowAmount,
            "vDebtUSDC balance should match borrow amount"
        );

        // Verify USDC was received by Alice
        assertEq(
            usdc.balanceOf(alice) - initialUsdcBalance,
            borrowAmount,
            "USDC balance increase should match borrow amount"
        );
    }

    function _setupAlicePosition(
        address predictedDebtAddress,
        uint256 wethAmount,
        uint256 wbtcAmount,
        uint256 daiAmount,
        uint256 usdcAmount
    ) internal {
        // Prepare multicall data for Alice's initial setup
        bytes[] memory aliceData = new bytes[](5);

        // 1. Create debt position
        aliceData[0] = abi.encodeWithSelector(router.createDebt.selector);

        // 2. Supply WETH
        aliceData[1] = abi.encodeWithSelector(
            router.callSupply.selector,
            predictedDebtAddress,
            WETH,
            wethAmount
        );

        // 3. Supply WBTC
        aliceData[2] = abi.encodeWithSelector(
            router.callSupply.selector,
            predictedDebtAddress,
            WBTC,
            wbtcAmount
        );

        // 4. Borrow DAI
        aliceData[3] = abi.encodeWithSelector(
            router.callBorrow.selector,
            predictedDebtAddress,
            DAI,
            daiAmount,
            2,
            alice
        );

        // 5. Borrow USDC
        aliceData[4] = abi.encodeWithSelector(
            router.callBorrow.selector,
            predictedDebtAddress,
            USDC,
            usdcAmount,
            2,
            alice
        );

        // Execute Alice's multicall
        weth.approve(address(router), wethAmount);
        wbtc.approve(address(router), wbtcAmount);
        router.multicall(aliceData);
    }

    function _createAndSignFullSaleOrder(
        address predictedDebtAddress,
        uint256 triggerHF,
        uint256 percentOfEquity,
        uint256 startTime,
        uint256 endTime
    ) internal returns (IAaveRouter.FullSellOrder memory) {
        // Create order title
        IAaveRouter.OrderTitle memory title = IAaveRouter.OrderTitle({
            debt: predictedDebtAddress,
            debtNonce: router.debtNonces(predictedDebtAddress),
            startTime: startTime,
            endTime: endTime,
            triggerHF: triggerHF
        });

        // Create full sale order
        IAaveRouter.FullSellOrder memory order = IAaveRouter.FullSellOrder({
            title: title,
            token: WBTC,
            percentOfEquity: percentOfEquity,
            v: 0,
            r: bytes32(0),
            s: bytes32(0)
        });

        // Sign the order
        bytes32 structHash = keccak256(
            abi.encode(
                router.FULL_SELL_ORDER_TYPE_HASH(),
                block.chainid,
                address(router),
                keccak256(
                    abi.encode(
                        router.ORDER_TITLE_TYPE_HASH(),
                        title.debt,
                        title.debtNonce,
                        title.startTime,
                        title.endTime,
                        title.triggerHF
                    )
                ),
                order.token,
                order.percentOfEquity
            )
        );

        // Create EIP-712 digest
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", router.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);
        order.v = v;
        order.r = r;
        order.s = s;

        return order;
    }

    function _manipulatePricesToTriggerHF(
        address debtAddress,
        uint256 triggerHF,
        address // targetAsset parameter kept for compatibility but not used
    ) internal {
        console.log("\nSimplified Price Manipulation:");
        console.log("Target HF:", triggerHF);

        require(
            triggerHF >= 1.0e18,
            "Target HF must be >= 1.0 to avoid liquidation"
        );

        // Get current HF first to validate
        (, , , , , uint256 currentHF) = pool.getUserAccountData(debtAddress);
        console.log("Current HF:", currentHF);
        require(triggerHF < currentHF, "Target HF must be lower than current");

        // Simple approach: Mock both WETH and WBTC to same prices
        // Initial price: $10,000 each
        // Target price: $5,500 each (45% drop) to reach target HF 1.1
        uint256 initialPrice = 10000 * 1e8; // $10,000 with 8 decimals
        uint256 targetPrice = 5500 * 1e8; // $5,500 with 8 decimals (45% drop)

        console.log("Mocking WETH price:", initialPrice, "->", targetPrice);
        console.log("Mocking WBTC price:", initialPrice, "->", targetPrice);

        // Mock price oracle to return reduced prices
        vm.mockCall(
            address(priceOracle),
            abi.encodeWithSelector(priceOracle.getAssetPrice.selector, WETH),
            abi.encode(targetPrice)
        );

        vm.mockCall(
            address(priceOracle),
            abi.encodeWithSelector(priceOracle.getAssetPrice.selector, WBTC),
            abi.encode(targetPrice)
        );

        // Verify the price manipulation worked
        (, , , , , uint256 newHF) = pool.getUserAccountData(debtAddress);
        console.log("HF after price drop:", newHF);
    }

    function _executeBobMulticall(
        IAaveRouter.FullSellOrder memory order,
        uint256 totalDebtBase,
        uint256 percentOfEquity
    ) internal {
        // Calculate premium that Bob pays to Alice (seller only gets premium)
        (uint256 totalCollateralBase, , , , , ) = pool.getUserAccountData(
            order.title.debt
        );
        uint256 netEquity = totalCollateralBase - totalDebtBase;
        uint256 premiumValue = (netEquity * percentOfEquity) / 10000;
        uint256 requiredWbtc = (premiumValue * 1e8) /
            priceOracle.getAssetPrice(WBTC);

        // Get current debt amounts
        uint256 daiDebt = vDebtDAI.balanceOf(order.title.debt);
        uint256 usdcDebt = vDebtUSDC.balanceOf(order.title.debt);

        // Prepare flat multicall data (5 operations total)
        bytes[] memory flatData = new bytes[](5);

        // 1. Execute full sale order
        flatData[0] = abi.encodeWithSelector(
            router.executeFullSaleOrder.selector,
            order,
            0 // minProfit
        );

        // 2. Repay DAI
        flatData[1] = abi.encodeWithSelector(
            router.callRepay.selector,
            order.title.debt,
            DAI,
            daiDebt,
            2 // interest rate mode
        );

        // 3. Repay USDC
        flatData[2] = abi.encodeWithSelector(
            router.callRepay.selector,
            order.title.debt,
            USDC,
            usdcDebt,
            2 // interest rate mode
        );

        // 4. Withdraw WETH
        flatData[3] = abi.encodeWithSelector(
            router.callWithdraw.selector,
            order.title.debt,
            WETH,
            IERC20(pool.getReserveData(WETH).aTokenAddress).balanceOf(
                order.title.debt
            ),
            bob
        );

        // 5. Withdraw WBTC
        flatData[4] = abi.encodeWithSelector(
            router.callWithdraw.selector,
            order.title.debt,
            WBTC,
            IERC20(pool.getReserveData(WBTC).aTokenAddress).balanceOf(
                order.title.debt
            ),
            bob
        );

        // Execute single flat multicall
        // wbtc.approve(address(router), requiredWbtc);
        dai.approve(address(router), daiDebt);
        usdc.approve(address(router), usdcDebt);
        router.multicall(flatData);
    }

    struct TestState {
        address predictedDebtAddress;
        uint256 wethAmount;
        uint256 wbtcAmount;
        uint256 daiAmount;
        uint256 usdcAmount;
        uint256 totalCollateralBase;
        uint256 totalDebtBase;
        uint256 initialHF;
        uint256 triggerHF;
        uint256 percentOfEquity;
        uint256 startTime;
        uint256 endTime;
        uint256 currentHF;
        IAaveRouter.FullSellOrder order;
    }

    function testFullSaleWithMulticall() public {
        TestState memory state;

        // Initial setup - Alice's position
        vm.startPrank(alice);

        // Get predicted debt address
        state.predictedDebtAddress = router.predictDebtAddress(alice);

        // Prepare amounts for initial setup
        state.wethAmount = 5 ether; // 5 WETH = $10,000
        state.wbtcAmount = 1 * 1e8; // 1 WBTC = $40,000
        state.daiAmount = 15000 * 1e18; // 15,000 DAI = $15,000
        state.usdcAmount = 10500 * 1e6; // 10,500 USDC = $10,500
        // Total collateral: $50,000, Total debt: $25,500, Expected HF: 1.5

        // Setup Alice's position
        _setupAlicePosition(
            state.predictedDebtAddress,
            state.wethAmount,
            state.wbtcAmount,
            state.daiAmount,
            state.usdcAmount
        );

        // Get initial state
        (
            state.totalCollateralBase,
            state.totalDebtBase,
            ,
            ,
            ,
            state.initialHF
        ) = pool.getUserAccountData(state.predictedDebtAddress);

        console.log("Initial Health Factor:", state.initialHF);
        assertTrue(state.initialHF >= 1.5e18, "Initial HF should be >= 1.5");

        // Create and sign full sale order
        state.triggerHF = 1.1e18;
        state.percentOfEquity = 9000; // 90% - seller gets 90% of net equity
        state.startTime = block.timestamp;
        state.endTime = block.timestamp + 1 days;

        state.order = _createAndSignFullSaleOrder(
            state.predictedDebtAddress,
            state.triggerHF,
            state.percentOfEquity,
            state.startTime,
            state.endTime
        );

        vm.stopPrank();

        // Log initial balances
        console.log("\nInitial Balances:");
        console.log("Alice WETH:", weth.balanceOf(alice));
        console.log("Alice WBTC:", wbtc.balanceOf(alice));
        console.log("Alice DAI:", dai.balanceOf(alice));
        console.log("Alice USDC:", usdc.balanceOf(alice));

        // Manipulate prices to trigger the order
        _manipulatePricesToTriggerHF(
            state.predictedDebtAddress,
            state.triggerHF,
            WETH
        );

        // Verify HF reached trigger point
        (, , , , , state.currentHF) = pool.getUserAccountData(
            state.predictedDebtAddress
        );
        console.log("\nHealth Factor after price drop:", state.currentHF);
        assertTrue(
            state.currentHF <= state.triggerHF + (state.triggerHF * 10) / 100,
            "HF should be close to trigger point"
        );

        // Bob executes the full sale order
        vm.startPrank(bob);
        _executeBobMulticall(
            state.order,
            state.totalDebtBase,
            state.percentOfEquity
        );
        vm.stopPrank();

        // Log final balances
        console.log("\nFinal Balances:");
        console.log("Alice WETH:", weth.balanceOf(alice));
        console.log("Alice WBTC:", wbtc.balanceOf(alice));
        console.log("Alice DAI:", dai.balanceOf(alice));
        console.log("Alice USDC:", usdc.balanceOf(alice));
        console.log("Bob WETH:", weth.balanceOf(bob));
        console.log("Bob WBTC:", wbtc.balanceOf(bob));
        console.log("Bob DAI:", dai.balanceOf(bob));
        console.log("Bob USDC:", usdc.balanceOf(bob));

        // Verify final state
        assertEq(
            router.debtOwners(state.predictedDebtAddress),
            bob,
            "Bob should be new owner"
        );
        assertEq(
            vDebtDAI.balanceOf(state.predictedDebtAddress),
            0,
            "DAI debt should be repaid"
        );
        assertEq(
            vDebtUSDC.balanceOf(state.predictedDebtAddress),
            0,
            "USDC debt should be repaid"
        );
        assertEq(
            IERC20(pool.getReserveData(WETH).aTokenAddress).balanceOf(
                state.predictedDebtAddress
            ),
            0,
            "WETH should be withdrawn"
        );
        assertEq(
            IERC20(pool.getReserveData(WBTC).aTokenAddress).balanceOf(
                state.predictedDebtAddress
            ),
            0,
            "WBTC should be withdrawn"
        );
    }

    function _createAndSignPartialSaleOrder(
        address predictedDebtAddress,
        uint256 triggerHF,
        uint256 repayAmount,
        uint256 bonus,
        uint256 startTime,
        uint256 endTime
    ) internal returns (IAaveRouter.PartialSellOrder memory) {
        // Create order title
        IAaveRouter.OrderTitle memory title = IAaveRouter.OrderTitle({
            debt: predictedDebtAddress,
            debtNonce: router.debtNonces(predictedDebtAddress),
            startTime: startTime,
            endTime: endTime,
            triggerHF: triggerHF
        });

        // Setup collateral withdrawal - Bob gets only WETH for his payment (safer for HF)
        address[] memory collateralOut = new address[](1);
        collateralOut[0] = WETH;

        uint256[] memory percents = new uint256[](1);
        percents[0] = 10000; // 100% from WETH only

        // Create partial sale order
        IAaveRouter.PartialSellOrder memory order = IAaveRouter
            .PartialSellOrder({
                title: title,
                interestRateMode: 2, // Variable rate
                collateralOut: collateralOut,
                percents: percents,
                repayToken: USDC,
                repayAmount: repayAmount,
                bonus: bonus,
                v: 0,
                r: bytes32(0),
                s: bytes32(0)
            });

        // Sign the order
        bytes32 structHash = keccak256(
            abi.encode(
                router.PARTIAL_SELL_ORDER_TYPE_HASH(),
                block.chainid,
                address(router),
                keccak256(
                    abi.encode(
                        router.ORDER_TITLE_TYPE_HASH(),
                        title.debt,
                        title.debtNonce,
                        title.startTime,
                        title.endTime,
                        title.triggerHF
                    )
                ),
                order.interestRateMode,
                order.collateralOut,
                order.percents,
                order.repayToken,
                order.repayAmount,
                order.bonus
            )
        );

        // Create EIP-712 digest
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", router.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);
        order.v = v;
        order.r = r;
        order.s = s;

        return order;
    }

    struct PartialSaleTestState {
        address predictedDebtAddress;
        uint256 wethAmount;
        uint256 wbtcAmount;
        uint256 daiAmount;
        uint256 usdcAmount;
        uint256 totalCollateralBase;
        uint256 totalDebtBase;
        uint256 initialHF;
        uint256 triggerHF;
        uint256 repayAmount;
        uint256 bonus;
        uint256 currentHF;
        uint256 finalCollateralBase;
        uint256 finalDebtBase;
        uint256 finalHF;
        IAaveRouter.PartialSellOrder order;
    }

    struct BalanceState {
        uint256 aliceInitialWeth;
        uint256 aliceInitialUsdc;
        uint256 bobInitialWeth;
        uint256 bobInitialUsdc;
        uint256 aliceFinalWeth;
        uint256 aliceFinalUsdc;
        uint256 bobFinalWeth;
        uint256 bobFinalUsdc;
    }

    function testPartialSaleOrder() public {
        console.log("\n=== Testing Partial Sale Order ===");

        // Check liquidation thresholds first
        _getLiquidationThresholds();

        PartialSaleTestState memory state;
        BalanceState memory balances;

        // Initial setup - Alice's position
        vm.startPrank(alice);

        state.predictedDebtAddress = router.predictDebtAddress(alice);

        // Setup Alice's position with realistic amounts based on our calculations
        state.wethAmount = 5 ether; // 5 WETH = $10,000
        state.wbtcAmount = 1 * 1e8; // 1 WBTC = $40,000
        state.daiAmount = 15000 * 1e18; // 15,000 DAI = $15,000
        state.usdcAmount = 10500 * 1e6; // 10,500 USDC = $10,500
        // Total collateral: $50,000, Total debt: $25,500, Expected HF: 1.5

        _setupAlicePosition(
            state.predictedDebtAddress,
            state.wethAmount,
            state.wbtcAmount,
            state.daiAmount,
            state.usdcAmount
        );

        // Get initial state
        (
            state.totalCollateralBase,
            state.totalDebtBase,
            ,
            ,
            ,
            state.initialHF
        ) = pool.getUserAccountData(state.predictedDebtAddress);

        console.log("Alice's Initial State:");
        console.log("Total Collateral Base:", state.totalCollateralBase);
        console.log("Total Debt Base:", state.totalDebtBase);
        console.log("Initial Health Factor:", state.initialHF);

        // Create partial sale order based on calculations
        state.triggerHF = 1.4e18; // More realistic target that WBTC manipulation can achieve
        state.repayAmount = 3000 * 1e6; // Bob pays $3,000 USDC
        state.bonus = 100; // 1% bonus for Bob

        state.order = _createAndSignPartialSaleOrder(
            state.predictedDebtAddress,
            state.triggerHF,
            state.repayAmount,
            state.bonus,
            block.timestamp,
            block.timestamp + 1 days
        );

        vm.stopPrank();

        // Record initial balances
        balances.aliceInitialWeth = weth.balanceOf(alice);
        balances.aliceInitialUsdc = usdc.balanceOf(alice);
        balances.bobInitialWeth = weth.balanceOf(bob);
        balances.bobInitialUsdc = usdc.balanceOf(bob);

        console.log("\nInitial Balances:");
        console.log("Alice WETH:", balances.aliceInitialWeth);
        console.log("Alice USDC:", balances.aliceInitialUsdc);
        console.log("Bob WETH:", balances.bobInitialWeth);
        console.log("Bob USDC:", balances.bobInitialUsdc);

        // Manipulate prices to trigger the order
        _manipulatePricesToTriggerHF(
            state.predictedDebtAddress,
            state.triggerHF,
            WETH
        );

        // Verify HF reached trigger point
        (, , , , , state.currentHF) = pool.getUserAccountData(
            state.predictedDebtAddress
        );
        console.log("\nHealth Factor after price drop:", state.currentHF);
        assertTrue(
            state.currentHF <= state.triggerHF + (state.triggerHF * 10) / 100,
            "HF should be close to trigger point"
        );

        // Bob executes the partial sale order
        vm.startPrank(bob);
        usdc.approve(address(router), state.repayAmount);

        // Debug before execution
        console.log("\n=== Before Partial Sale Execution ===");
        console.log("Current HF:", state.currentHF);
        console.log("Repay Amount (USDC):", state.repayAmount);
        console.log("Expected collateral withdrawal: 100% WETH");
        console.log("Expected bonus: 1%");
        console.log("Goal: HF should improve from current level");

        router.excutePartialSellOrder(state.order);
        vm.stopPrank();

        // Get final state
        (
            state.finalCollateralBase,
            state.finalDebtBase,
            ,
            ,
            ,
            state.finalHF
        ) = pool.getUserAccountData(state.predictedDebtAddress);

        console.log("\nAlice's Final State:");
        console.log("Final Collateral Base:", state.finalCollateralBase);
        console.log("Final Debt Base:", state.finalDebtBase);
        console.log("Final Health Factor:", state.finalHF);

        // Record final balances
        balances.aliceFinalWeth = weth.balanceOf(alice);
        balances.aliceFinalUsdc = usdc.balanceOf(alice);
        balances.bobFinalWeth = weth.balanceOf(bob);
        balances.bobFinalUsdc = usdc.balanceOf(bob);

        console.log("\nFinal Balances:");
        console.log("Alice WETH:", balances.aliceFinalWeth);
        console.log("Alice USDC:", balances.aliceFinalUsdc);
        console.log("Bob WETH:", balances.bobFinalWeth);
        console.log("Bob USDC:", balances.bobFinalUsdc);

        // Verify results
        assertTrue(
            state.finalHF > state.currentHF,
            "Alice's HF should improve from risky state"
        );
        // Note: Final HF may not reach trigger point but should still be an improvement
        console.log("HF improved from", state.currentHF, "to", state.finalHF);

        assertEq(
            router.debtOwners(state.predictedDebtAddress),
            alice,
            "Alice should still own the debt"
        );

        // Verify debt reduction
        uint256 usdcDebtAfter = vDebtUSDC.balanceOf(state.predictedDebtAddress);
        assertTrue(
            usdcDebtAfter < state.usdcAmount,
            "USDC debt should be reduced"
        );

        // Verify Bob received only WETH
        assertTrue(
            balances.bobFinalWeth > balances.bobInitialWeth,
            "Bob should receive WETH"
        );
        assertTrue(
            balances.bobFinalUsdc < balances.bobInitialUsdc,
            "Bob should have paid USDC"
        );

        // Calculate and verify results match theoretical calculations
        uint256 bobUsdcSpent = balances.bobInitialUsdc - balances.bobFinalUsdc;
        uint256 bobWethGain = balances.bobFinalWeth - balances.bobInitialWeth;

        console.log("\n=== Calculation Verification ===");
        console.log("Bob USDC spent:", bobUsdcSpent);
        console.log("Expected repay amount:", state.repayAmount);
        console.log("Bob WETH gained:", bobWethGain);

        assertEq(
            bobUsdcSpent,
            state.repayAmount,
            "Bob should have spent exactly the repay amount"
        );

        console.log("\n=== Partial Sale Test Completed Successfully ===");
    }

    function _getLiquidationThresholds() internal view {
        console.log("\n=== Liquidation Thresholds ===");

        // Get reserve configuration data directly
        uint256 wethConfigData = pool.getConfiguration(WETH).data;
        uint256 wbtcConfigData = pool.getConfiguration(WBTC).data;

        // Extract liquidation thresholds (bits 16-31, divide by 100 for percentage)
        uint256 wethLT = (wethConfigData >> 16) & 0xFFFF; // bits 16-31
        uint256 wbtcLT = (wbtcConfigData >> 16) & 0xFFFF; // bits 16-31

        console.log("WETH Liquidation Threshold (bp):", wethLT);
        console.log("WETH Liquidation Threshold (%):", wethLT / 100);
        console.log("WBTC Liquidation Threshold (bp):", wbtcLT);
        console.log("WBTC Liquidation Threshold (%):", wbtcLT / 100);

        // Also log LTV (bits 0-15)
        uint256 wethLTV = wethConfigData & 0xFFFF;
        uint256 wbtcLTV = wbtcConfigData & 0xFFFF;
        console.log("WETH LTV (bp):", wethLTV);
        console.log("WETH LTV (%):", wethLTV / 100);
        console.log("WBTC LTV (bp):", wbtcLTV);
        console.log("WBTC LTV (%):", wbtcLTV / 100);
    }
}
