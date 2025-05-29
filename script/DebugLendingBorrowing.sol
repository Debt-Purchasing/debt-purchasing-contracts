// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";

contract DebugLendingBorrowing is Script {
    // Contract addresses - will be set from PoolAddressesProvider
    address poolAddress;
    address poolAddressesProvider = 0xb830887eE23d3f9Ed8c27dbF7DcFe63037765475; // Updated from deployment

    // Deterministic ganache accounts (from mnemonic "test test test test test test test test test test test junk")
    address constant USER1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Account #0
    address constant USER2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Account #1
    address constant USER3 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Account #2
    address constant USER4 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906; // Account #3
    address constant USER5 = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65; // Account #4

    // Token addresses - will be populated from deployment
    mapping(string => address) tokenAddresses;
    mapping(string => IERC20) tokens;

    IPool pool;

    struct UserStrategy {
        address user;
        string depositAsset;
        uint256 depositAmount;
        string borrowAsset;
        uint256 borrowAmount;
        string description;
    }

    function run() external {
        console.log("=======================================================");
        console.log(unicode"🏦 MULTI-USER AAVE V3 TESTING SCENARIO");
        console.log("=======================================================");
        console.log("");

        // Initialize pool address from PoolAddressesProvider
        initializePoolAddress();

        // Initialize token addresses (hardcoded for now - could be automated)
        initializeTokenAddresses();

        // Create realistic multi-user scenario
        executeMultiUserScenario();

        console.log(unicode"🎉 MULTI-USER SCENARIO COMPLETED SUCCESSFULLY!");
        console.log("=======================================================");
    }

    function initializePoolAddress() internal {
        console.log(
            unicode"🔍 Getting Pool address from PoolAddressesProvider..."
        );

        (bool success, bytes memory result) = poolAddressesProvider.call(
            abi.encodeWithSignature("getPool()")
        );

        require(success, "Failed to get Pool address");
        poolAddress = abi.decode(result, (address));
        pool = IPool(poolAddress);

        console.log(unicode"✅ Pool address:", poolAddress);
        console.log("");
    }

    function initializeTokenAddresses() internal {
        console.log(unicode"🪙 Initializing token addresses...");

        // Updated with actual deployed SimpleERC20 token addresses (checksummed)
        tokenAddresses["WETH"] = 0xF5b81Fe0B6F378f9E6A3fb6A6cD1921FCeA11799;
        tokenAddresses["USDC"] = 0x67baFF31318638F497f4c4894Cd73918563942c8;
        tokenAddresses["DAI"] = address(0); // Will be set from deployment
        tokenAddresses["WBTC"] = address(0); // Will be set from deployment
        tokenAddresses["LINK"] = address(0); // Will be set from deployment

        // Initialize IERC20 interfaces
        tokens["WETH"] = IERC20(tokenAddresses["WETH"]);
        tokens["USDC"] = IERC20(tokenAddresses["USDC"]);

        console.log(unicode"✅ WETH:", tokenAddresses["WETH"]);
        console.log(unicode"✅ USDC:", tokenAddresses["USDC"]);
        console.log("");
    }

    function executeMultiUserScenario() internal {
        console.log(
            unicode"🎭 EXECUTING MULTI-USER LENDING/BORROWING SCENARIO"
        );
        console.log("================================================");
        console.log("");

        // Define user strategies
        UserStrategy[5] memory strategies = [
            UserStrategy({
                user: USER1,
                depositAsset: "WETH",
                depositAmount: 50 ether, // 50 WETH
                borrowAsset: "USDC",
                borrowAmount: 50000 * 1e6, // 50,000 USDC
                description: unicode"🐋 Whale: Large WETH deposit, borrowing USDC"
            }),
            UserStrategy({
                user: USER2,
                depositAsset: "USDC",
                depositAmount: 100000 * 1e6, // 100,000 USDC
                borrowAsset: "WETH",
                borrowAmount: 10 ether, // 10 WETH
                description: unicode"💰 Stablecoin Lender: USDC → WETH"
            }),
            UserStrategy({
                user: USER3,
                depositAsset: "WETH",
                depositAmount: 20 ether, // 20 WETH
                borrowAsset: "USDC",
                borrowAmount: 20000 * 1e6, // 20,000 USDC
                description: unicode"⚖️  Balanced: Medium WETH deposit"
            }),
            UserStrategy({
                user: USER4,
                depositAsset: "USDC",
                depositAmount: 50000 * 1e6, // 50,000 USDC
                borrowAsset: "WETH",
                borrowAmount: 5 ether, // 5 WETH
                description: unicode"🏛️  Institution: Conservative USDC lending"
            }),
            UserStrategy({
                user: USER5,
                depositAsset: "WETH",
                depositAmount: 10 ether, // 10 WETH
                borrowAsset: "USDC",
                borrowAmount: 8000 * 1e6, // 8,000 USDC
                description: unicode"🏠 Retail: Small position management"
            })
        ];

        // Execute each user's strategy
        for (uint i = 0; i < strategies.length; i++) {
            executeUserStrategy(strategies[i], i + 1);
            console.log("");
        }

        // Final market state summary
        showMarketSummary();
    }

    function executeUserStrategy(
        UserStrategy memory strategy,
        uint256 userNumber
    ) internal {
        console.log(unicode"👤 USER", userNumber, "STRATEGY");
        console.log("================");
        console.log(unicode"📝", strategy.description);
        console.log(
            unicode"💰 Deposit:",
            formatAmount(strategy.depositAmount, strategy.depositAsset),
            strategy.depositAsset
        );
        console.log(
            unicode"🏦 Borrow:",
            formatAmount(strategy.borrowAmount, strategy.borrowAsset),
            strategy.borrowAsset
        );
        console.log("");

        // Start broadcasting as this user
        vm.startBroadcast(getPrivateKey(strategy.user));

        // Step 1: Mint tokens for this user
        mintTokensForUser(
            strategy.user,
            strategy.depositAsset,
            strategy.depositAmount
        );

        // Step 2: Approve pool
        approvePool(strategy.depositAsset, strategy.depositAmount);

        // Step 3: Supply (deposit) assets
        supplyAsset(
            strategy.user,
            strategy.depositAsset,
            strategy.depositAmount
        );

        // Step 4: Borrow assets (if there's liquidity)
        borrowAsset(strategy.user, strategy.borrowAsset, strategy.borrowAmount);

        // Step 5: Show user's final position
        showUserPosition(strategy.user, userNumber);

        vm.stopBroadcast();
    }

    function mintTokensForUser(
        address user,
        string memory asset,
        uint256 amount
    ) internal {
        console.log(unicode"🪙 Minting tokens for user...");
        console.log("Asset:", asset);
        console.log("Amount:", formatAmount(amount, asset));
        console.log("User:", user);

        address tokenAddress = tokenAddresses[asset];
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("mint(address,uint256)", user, amount)
        );

        if (success) {
            console.log(unicode"✅ Minted successfully");
        } else {
            console.log(unicode"❌ Mint failed");
        }
    }

    function approvePool(string memory asset, uint256 amount) internal {
        console.log(unicode"✅ Approving", asset, "to Pool...");
        bool success = tokens[asset].approve(poolAddress, amount);
        console.log("Approval success:", success);
    }

    function supplyAsset(
        address user,
        string memory asset,
        uint256 amount
    ) internal {
        console.log(
            unicode"🏦 Supplying",
            formatAmount(amount, asset),
            asset,
            "to Aave..."
        );

        try pool.supply(tokenAddresses[asset], amount, user, 0) {
            console.log(unicode"✅ Supply successful");
        } catch Error(string memory reason) {
            console.log(unicode"❌ Supply failed:", reason);
        } catch {
            console.log(unicode"❌ Supply failed with unknown error");
        }
    }

    function borrowAsset(
        address user,
        string memory asset,
        uint256 amount
    ) internal {
        console.log(
            unicode"💸 Borrowing",
            formatAmount(amount, asset),
            asset,
            "from Aave..."
        );

        try pool.borrow(tokenAddresses[asset], amount, 2, 0, user) {
            console.log(unicode"✅ Borrow successful");
        } catch Error(string memory reason) {
            console.log(unicode"❌ Borrow failed:", reason);
            console.log(
                unicode"💡 This is normal if insufficient liquidity in the asset"
            );
        } catch {
            console.log(unicode"❌ Borrow failed with unknown error");
        }
    }

    function showUserPosition(address user, uint256 userNumber) internal view {
        console.log(unicode"📊 USER", userNumber, "FINAL POSITION:");

        // Show token balances
        uint256 wethBalance = tokens["WETH"].balanceOf(user);
        uint256 usdcBalance = tokens["USDC"].balanceOf(user);

        console.log(
            unicode"💰 WETH balance:",
            formatAmount(wethBalance, "WETH")
        );
        console.log(
            unicode"💰 USDC balance:",
            formatAmount(usdcBalance, "USDC")
        );

        // Show aToken balances (if any)
        try pool.getReserveData(tokenAddresses["WETH"]) returns (
            DataTypes.ReserveData memory reserveData
        ) {
            uint256 aTokenBalance = IERC20(reserveData.aTokenAddress).balanceOf(
                user
            );
            if (aTokenBalance > 0) {
                console.log(
                    unicode"🏦 aWETH balance:",
                    formatAmount(aTokenBalance, "WETH")
                );
            }
        } catch {}

        try pool.getReserveData(tokenAddresses["USDC"]) returns (
            DataTypes.ReserveData memory reserveData
        ) {
            uint256 aTokenBalance = IERC20(reserveData.aTokenAddress).balanceOf(
                user
            );
            if (aTokenBalance > 0) {
                console.log(
                    unicode"🏦 aUSDC balance:",
                    formatAmount(aTokenBalance, "USDC")
                );
            }
        } catch {}
    }

    function showMarketSummary() internal view {
        console.log(unicode"📈 MARKET SUMMARY");
        console.log("================");

        // Show total liquidity for each asset
        try pool.getReserveData(tokenAddresses["WETH"]) returns (
            DataTypes.ReserveData memory reserveData
        ) {
            uint256 totalSupply = IERC20(reserveData.aTokenAddress)
                .totalSupply();
            console.log(
                unicode"🏦 Total WETH supplied:",
                formatAmount(totalSupply, "WETH")
            );
        } catch {}

        try pool.getReserveData(tokenAddresses["USDC"]) returns (
            DataTypes.ReserveData memory reserveData
        ) {
            uint256 totalSupply = IERC20(reserveData.aTokenAddress)
                .totalSupply();
            console.log(
                unicode"🏦 Total USDC supplied:",
                formatAmount(totalSupply, "USDC")
            );
        } catch {}

        console.log("");
        console.log(unicode"✅ Multi-user ecosystem created successfully!");
        console.log(
            unicode"💡 Each user has different positions, creating natural market dynamics"
        );
    }

    // Helper functions
    function formatAmount(
        uint256 amount,
        string memory asset
    ) internal pure returns (string memory) {
        if (keccak256(bytes(asset)) == keccak256(bytes("WETH"))) {
            return
                string(
                    abi.encodePacked(
                        uint2str(amount / 1e18),
                        ".",
                        uint2str((amount % 1e18) / 1e17)
                    )
                );
        } else if (keccak256(bytes(asset)) == keccak256(bytes("USDC"))) {
            return
                string(
                    abi.encodePacked(
                        uint2str(amount / 1e6),
                        ".",
                        uint2str((amount % 1e6) / 1e5)
                    )
                );
        }
        return uint2str(amount);
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 temp = _i;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_i != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(_i % 10)));
            _i /= 10;
        }
        return string(buffer);
    }

    function getPrivateKey(address user) internal pure returns (uint256) {
        // Return private key for deterministic ganache accounts
        if (user == USER1)
            return
                0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (user == USER2)
            return
                0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        if (user == USER3)
            return
                0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        if (user == USER4)
            return
                0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;
        if (user == USER5)
            return
                0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a;
        revert("Unknown user");
    }
}
