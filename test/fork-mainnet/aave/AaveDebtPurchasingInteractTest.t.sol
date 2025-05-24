// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SetUpAave.t.sol";
import "../../../src/aave/AaveRouter.sol";
import "../../../src/aave/AaveDebt.sol";

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
        uint256 fullSaleExtra,
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
            fullSaleToken: WBTC,
            fullSaleExtra: fullSaleExtra,
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
                order.fullSaleToken,
                order.fullSaleExtra
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, structHash);
        order.v = v;
        order.r = r;
        order.s = s;

        return order;
    }

    function _manipulatePricesToTriggerHF(
        address debtAddress,
        uint256 triggerHF
    ) internal {
        // Get current state
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            ,
            ,
            ,
            uint256 currentHF
        ) = pool.getUserAccountData(debtAddress);

        console.log("\nPrice Manipulation Debug:");
        console.log("Current HF:", currentHF);
        console.log("Target HF:", triggerHF);
        console.log("Total Collateral Base:", totalCollateralBase);
        console.log("Total Debt Base:", totalDebtBase);

        // Calculate required price decrease to reach target HF
        // HF = (totalCollateralBase * priceFactor) / totalDebtBase
        // targetHF = (totalCollateralBase * priceFactor) / totalDebtBase
        // priceFactor = (targetHF * totalDebtBase) / totalCollateralBase
        uint256 priceFactor = (triggerHF * totalDebtBase) / totalCollateralBase;

        // Convert price factor to percentage (e.g., 0.8 = 80% of current price)
        uint256 pricePercentage = (priceFactor * 100) / 1e18;

        console.log("Calculated Price Factor:", priceFactor);
        console.log("Price Percentage:", pricePercentage);

        // Get current prices
        uint256 currentWethPrice = priceOracle.getAssetPrice(WETH);
        uint256 currentWbtcPrice = priceOracle.getAssetPrice(WBTC);

        // Calculate new prices
        uint256 newWethPrice = (currentWethPrice * pricePercentage) / 100;
        uint256 newWbtcPrice = (currentWbtcPrice * pricePercentage) / 100;

        console.log("Current WETH Price:", currentWethPrice);
        console.log("New WETH Price:", newWethPrice);
        console.log("Current WBTC Price:", currentWbtcPrice);
        console.log("New WBTC Price:", newWbtcPrice);

        vm.mockCall(
            address(priceOracle),
            abi.encodeWithSelector(priceOracle.getAssetPrice.selector, WETH),
            abi.encode(newWethPrice)
        );
        vm.mockCall(
            address(priceOracle),
            abi.encodeWithSelector(priceOracle.getAssetPrice.selector, WBTC),
            abi.encode(newWbtcPrice)
        );
    }

    function _executeBobMulticall(
        IAaveRouter.FullSellOrder memory order,
        uint256 totalDebtBase,
        uint256 fullSaleExtra
    ) internal {
        // Calculate required WBTC amount
        uint256 basePayValue = (totalDebtBase * fullSaleExtra) / 10000;
        uint256 wbtcPrice = priceOracle.getAssetPrice(WBTC);
        uint256 requiredWbtc = (basePayValue * 1e8) / wbtcPrice;

        // Get current debt amounts
        uint256 daiDebt = vDebtDAI.balanceOf(order.title.debt);
        uint256 usdcDebt = vDebtUSDC.balanceOf(order.title.debt);

        // Prepare Bob's multicall data
        bytes[] memory bobData = new bytes[](2);

        // 1. Execute full sale order
        bobData[0] = abi.encodeWithSelector(
            router.executeFullSaleOrder.selector,
            order,
            0 // minProfit
        );

        // 2. Prepare repay and withdraw operations
        bytes[] memory repayWithdrawData = new bytes[](4);

        // Repay DAI
        repayWithdrawData[0] = abi.encodeWithSelector(
            router.callRepay.selector,
            order.title.debt,
            DAI,
            daiDebt,
            2 // interest rate mode
        );

        // Repay USDC
        repayWithdrawData[1] = abi.encodeWithSelector(
            router.callRepay.selector,
            order.title.debt,
            USDC,
            usdcDebt,
            2 // interest rate mode
        );

        // Withdraw WETH
        repayWithdrawData[2] = abi.encodeWithSelector(
            router.callWithdraw.selector,
            order.title.debt,
            WETH,
            IERC20(pool.getReserveData(WETH).aTokenAddress).balanceOf(
                order.title.debt
            ),
            bob
        );

        // Withdraw WBTC
        repayWithdrawData[3] = abi.encodeWithSelector(
            router.callWithdraw.selector,
            order.title.debt,
            WBTC,
            IERC20(pool.getReserveData(WBTC).aTokenAddress).balanceOf(
                order.title.debt
            ),
            bob
        );

        // Add repay and withdraw operations to Bob's multicall
        bobData[1] = abi.encodeWithSelector(
            router.multicall.selector,
            repayWithdrawData
        );

        // Execute Bob's multicall
        wbtc.approve(address(router), requiredWbtc);
        dai.approve(address(router), daiDebt);
        usdc.approve(address(router), usdcDebt);
        router.multicall(bobData);
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
        uint256 fullSaleExtra;
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
        state.wethAmount = 1 ether;
        state.wbtcAmount = 0.1 * 1e8; // 0.1 WBTC
        state.daiAmount = 1000 * 1e18; // 1000 DAI
        state.usdcAmount = 1000 * 1e6; // 1000 USDC

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
        state.fullSaleExtra = 200; // 2%
        state.startTime = block.timestamp;
        state.endTime = block.timestamp + 1 days;

        state.order = _createAndSignFullSaleOrder(
            state.predictedDebtAddress,
            state.triggerHF,
            state.fullSaleExtra,
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

        // Manipulate prices to reach trigger HF
        _manipulatePricesToTriggerHF(
            state.predictedDebtAddress,
            state.triggerHF
        );

        // Verify HF reached trigger point
        (, , , , , state.currentHF) = pool.getUserAccountData(
            state.predictedDebtAddress
        );
        console.log("\nHealth Factor after price change:", state.currentHF);
        assertTrue(
            state.currentHF <= state.triggerHF,
            "HF should be <= trigger point"
        );

        // Bob executes the full sale order
        vm.startPrank(bob);
        _executeBobMulticall(
            state.order,
            state.totalDebtBase,
            state.fullSaleExtra
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
}
