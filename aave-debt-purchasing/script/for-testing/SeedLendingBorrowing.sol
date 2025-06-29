// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";

contract SeedLendingBorrowing is Script {
    // Pool configuration
    address poolAddress;
    address poolAddressesProvider;
    IPool pool;

    // Token configuration - will be loaded from .env.local
    struct TokenInfo {
        address tokenAddress;
        IERC20 token;
        uint8 decimals;
        uint256 baseAmount;
        uint256 whaleAmount;
        uint256 borrowAmount;
        string symbol;
    }

    TokenInfo[12] tokens;
    uint256 tokenCount = 12;

    // User accounts (101 anvil accounts: 0-100)
    address[101] users;
    uint256[101] privateKeys;

    // State tracking
    uint256 totalSupplies = 0;
    uint256 totalBorrows = 0;
    uint256 successfulSupplies = 0;
    uint256 successfulBorrows = 0;

    function run() external {
        console.log("=======================================================");
        console.log(unicode"🌾 SEEDING AAVE V3 WITH WHALE + 100 USERS");
        console.log("=======================================================");
        console.log("");

        // Initialize everything
        initializeAccounts();
        initializePool();
        initializeTokens();

        console.log(unicode"🚀 Starting comprehensive seed operation...");
        console.log(unicode"🐋 Phase 1: Whale setup (Account 0)");
        console.log(
            unicode"👥 Phase 2: 100 users supply operations (Account 1-100)"
        );
        console.log(
            unicode"💸 Phase 3: 100 users borrow operations (Account 1-100)"
        );
        console.log("");

        // Execute seeding operations
        executeSeedOperations();

        // Show final results
        showFinalResults();
    }

    function initializeAccounts() internal {
        console.log(unicode"👥 Initializing 101 accounts (0-100)...");

        // Use the same mnemonic as anvil: "test test test test test test test test test test test junk"
        string
            memory mnemonic = "test test test test test test test test test test test junk";

        // Derive all 101 private keys from mnemonic (derivation path: m/44'/60'/0'/0/i)
        for (uint256 i = 0; i < 101; i++) {
            privateKeys[i] = vm.deriveKey(mnemonic, uint32(i));
            users[i] = vm.addr(privateKeys[i]);
        }

        console.log(unicode"✅ Whale account (0):", users[0]);
        console.log(unicode"✅ User accounts (1-100): Generated");
        console.log("");
    }

    function initializePool() internal {
        poolAddressesProvider = vm.envAddress("POOL_ADDRESSES_PROVIDER");
        poolAddress = vm.envAddress("POOL_PROXY");
        pool = IPool(poolAddress);

        console.log(unicode"🏊 Pool:", poolAddress);
        console.log(unicode"🏛️ Provider:", poolAddressesProvider);
        console.log("");
    }

    function initializeTokens() internal {
        console.log(unicode"🪙 Loading all 12 tokens from .env.local...");

        // Load all token addresses from environment with fixed amounts
        tokens[0] = TokenInfo({
            tokenAddress: vm.envAddress("WETH_ADDRESS"),
            token: IERC20(vm.envAddress("WETH_ADDRESS")),
            decimals: 18,
            baseAmount: 5 ether, // 5 WETH per user
            whaleAmount: 1000 ether, // 1000 WETH whale
            borrowAmount: 1 ether, // 1 WETH borrow
            symbol: "WETH"
        });

        tokens[1] = TokenInfo({
            tokenAddress: vm.envAddress("WSTETH_ADDRESS"),
            token: IERC20(vm.envAddress("WSTETH_ADDRESS")),
            decimals: 18,
            baseAmount: 3 ether, // 3 wstETH per user
            whaleAmount: 500 ether, // 500 wstETH whale
            borrowAmount: 1 ether, // 1 wstETH borrow
            symbol: "wstETH"
        });

        tokens[2] = TokenInfo({
            tokenAddress: vm.envAddress("WBTC_ADDRESS"),
            token: IERC20(vm.envAddress("WBTC_ADDRESS")),
            decimals: 8,
            baseAmount: 1 * 1e8, // 1 WBTC per user
            whaleAmount: 100 * 1e8, // 100 WBTC whale
            borrowAmount: 1e7, // 0.1 WBTC borrow
            symbol: "WBTC"
        });

        tokens[3] = TokenInfo({
            tokenAddress: vm.envAddress("USDC_ADDRESS"),
            token: IERC20(vm.envAddress("USDC_ADDRESS")),
            decimals: 6,
            baseAmount: 10000 * 1e6, // 10k USDC per user
            whaleAmount: 5000000 * 1e6, // 5M USDC whale
            borrowAmount: 1000 * 1e6, // 1k USDC borrow
            symbol: "USDC"
        });

        tokens[4] = TokenInfo({
            tokenAddress: vm.envAddress("DAI_ADDRESS"),
            token: IERC20(vm.envAddress("DAI_ADDRESS")),
            decimals: 18,
            baseAmount: 8000 ether, // 8k DAI per user
            whaleAmount: 3000000 ether, // 3M DAI whale
            borrowAmount: 1000 ether, // 1k DAI borrow
            symbol: "DAI"
        });

        tokens[5] = TokenInfo({
            tokenAddress: vm.envAddress("LINK_ADDRESS"),
            token: IERC20(vm.envAddress("LINK_ADDRESS")),
            decimals: 18,
            baseAmount: 500 ether, // 500 LINK per user
            whaleAmount: 100000 ether, // 100k LINK whale
            borrowAmount: 50 ether, // 50 LINK borrow
            symbol: "LINK"
        });

        tokens[6] = TokenInfo({
            tokenAddress: vm.envAddress("AAVE_ADDRESS"),
            token: IERC20(vm.envAddress("AAVE_ADDRESS")),
            decimals: 18,
            baseAmount: 100 ether, // 100 AAVE per user
            whaleAmount: 10000 ether, // 10k AAVE whale
            borrowAmount: 10 ether, // 10 AAVE borrow (but borrowing disabled)
            symbol: "AAVE"
        });

        tokens[7] = TokenInfo({
            tokenAddress: vm.envAddress("CBETH_ADDRESS"),
            token: IERC20(vm.envAddress("CBETH_ADDRESS")),
            decimals: 18,
            baseAmount: 3 ether, // 3 cbETH per user
            whaleAmount: 500 ether, // 500 cbETH whale
            borrowAmount: 1 ether, // 1 cbETH borrow
            symbol: "cbETH"
        });

        tokens[8] = TokenInfo({
            tokenAddress: vm.envAddress("USDT_ADDRESS"),
            token: IERC20(vm.envAddress("USDT_ADDRESS")),
            decimals: 6,
            baseAmount: 9000 * 1e6, // 9k USDT per user
            whaleAmount: 5000000 * 1e6, // 5M USDT whale
            borrowAmount: 1000 * 1e6, // 1k USDT borrow
            symbol: "USDT"
        });

        tokens[9] = TokenInfo({
            tokenAddress: vm.envAddress("RETH_ADDRESS"),
            token: IERC20(vm.envAddress("RETH_ADDRESS")),
            decimals: 18,
            baseAmount: 3 ether, // 3 rETH per user
            whaleAmount: 500 ether, // 500 rETH whale
            borrowAmount: 1 ether, // 1 rETH borrow
            symbol: "rETH"
        });

        tokens[10] = TokenInfo({
            tokenAddress: vm.envAddress("LUSD_ADDRESS"),
            token: IERC20(vm.envAddress("LUSD_ADDRESS")),
            decimals: 18,
            baseAmount: 7000 ether, // 7k LUSD per user
            whaleAmount: 2000000 ether, // 2M LUSD whale
            borrowAmount: 1000 ether, // 1k LUSD borrow
            symbol: "LUSD"
        });

        tokens[11] = TokenInfo({
            tokenAddress: vm.envAddress("CRV_ADDRESS"),
            token: IERC20(vm.envAddress("CRV_ADDRESS")),
            decimals: 18,
            baseAmount: 10000 ether, // 10k CRV per user
            whaleAmount: 1000000 ether, // 1M CRV whale
            borrowAmount: 1000 ether, // 1k CRV borrow
            symbol: "CRV"
        });

        console.log(unicode"✅ All 12 tokens loaded successfully:");
        for (uint i = 0; i < tokenCount; i++) {
            console.log(
                unicode"   ",
                tokens[i].symbol,
                ":",
                tokens[i].tokenAddress
            );
        }
        console.log("");
    }

    function executeSeedOperations() internal {
        // Phase 1: Whale setup
        executeWhaleSetup();

        // Phase 2: User supplies (Account 1-100)
        executeUserSupplies();

        // Phase 3: User borrows (Account 1-100)
        executeUserBorrows();
    }

    function executeWhaleSetup() internal {
        console.log(unicode"🐋 PHASE 1: WHALE LIQUIDITY SETUP");
        console.log("==================================");
        console.log(
            unicode"💰 Account 0 supplying massive liquidity for all 12 tokens..."
        );
        console.log("");

        address whale = users[0];
        uint256 whaleKey = privateKeys[0];

        for (uint i = 0; i < tokenCount; i++) {
            TokenInfo memory token = tokens[i];

            console.log(unicode"🐋 Whale supplying");
            console.log(
                "Amount:",
                formatAmount(token.whaleAmount, token.decimals)
            );
            console.log("Token:", token.symbol);

            // Mint tokens to whale
            vm.broadcast(whaleKey);
            (bool mintSuccess, ) = token.tokenAddress.call(
                abi.encodeWithSignature(
                    "mint(address,uint256)",
                    whale,
                    token.whaleAmount
                )
            );

            if (!mintSuccess) {
                console.log(unicode"❌ Mint failed");
                continue;
            }

            // Approve pool
            vm.broadcast(whaleKey);
            bool approveSuccess = token.token.approve(
                poolAddress,
                token.whaleAmount
            );

            if (!approveSuccess) {
                console.log(unicode"❌ Approve failed");
                continue;
            }

            // Supply to pool
            vm.broadcast(whaleKey);
            try pool.supply(token.tokenAddress, token.whaleAmount, whale, 0) {
                console.log(unicode"✅ Success");
                successfulSupplies++;
            } catch Error(string memory reason) {
                console.log(unicode"❌ Failed:", reason);
            } catch {
                console.log(unicode"❌ Failed: Unknown error");
            }

            totalSupplies++;
        }

        console.log("");
        console.log(
            unicode"🎉 Whale setup completed! Market now has massive liquidity."
        );
        console.log("");
    }

    function executeUserSupplies() internal {
        console.log(
            unicode"🌱 PHASE 2: USER SUPPLY OPERATIONS (Account 1-100)"
        );
        console.log("===================================================");

        // Execute 100 supply operations (users 1-100)
        for (uint i = 1; i <= 100; i++) {
            executeUserSupplyOperation(i);
        }
        console.log("");
    }

    function executeUserBorrows() internal {
        console.log(
            unicode"💸 PHASE 3: USER BORROW OPERATIONS (Account 1-100)"
        );
        console.log("===================================================");

        // Execute 100 borrow operations (users 1-100)
        for (uint i = 1; i <= 100; i++) {
            executeUserBorrowOperation(i);
        }
        console.log("");
    }

    function executeUserSupplyOperation(uint256 userIndex) internal {
        // Select token based on user index (cycle through tokens)
        uint256 tokenIndex = userIndex % tokenCount;

        address user = users[userIndex];
        TokenInfo memory selectedToken = tokens[tokenIndex];
        uint256 userKey = privateKeys[userIndex];

        console.log(unicode"🏦 Supply operation", userIndex);
        console.log(
            "Amount:",
            formatAmount(selectedToken.baseAmount, selectedToken.decimals)
        );
        console.log("Token:", selectedToken.symbol);
        console.log("User:", userIndex);

        // Mint tokens to user
        vm.broadcast(userKey);
        (bool mintSuccess, ) = selectedToken.tokenAddress.call(
            abi.encodeWithSignature(
                "mint(address,uint256)",
                user,
                selectedToken.baseAmount
            )
        );

        if (!mintSuccess) {
            console.log(unicode"❌ Mint failed");
            totalSupplies++;
            return;
        }

        // Approve pool
        vm.broadcast(userKey);
        bool approveSuccess = selectedToken.token.approve(
            poolAddress,
            selectedToken.baseAmount
        );

        if (!approveSuccess) {
            console.log(unicode"❌ Approve failed");
            totalSupplies++;
            return;
        }

        // Supply to pool
        vm.broadcast(userKey);
        try
            pool.supply(
                selectedToken.tokenAddress,
                selectedToken.baseAmount,
                user,
                0
            )
        {
            successfulSupplies++;
            console.log(unicode"✅ Success");
        } catch Error(string memory reason) {
            console.log(unicode"❌ Failed:", reason);
        } catch {
            console.log(unicode"❌ Failed: Unknown error");
        }

        totalSupplies++;
    }

    function executeUserBorrowOperation(uint256 userIndex) internal {
        // Select different token for borrowing (offset by 6 to ensure different from supply)
        uint256 tokenIndex = (userIndex + 6) % tokenCount;

        if (tokenIndex == 6) {
            return;
        }

        address user = users[userIndex];
        TokenInfo memory selectedToken = tokens[tokenIndex];
        uint256 userKey = privateKeys[userIndex];

        console.log(unicode"💸 Borrow operation", userIndex);
        console.log(
            "Amount:",
            formatAmount(selectedToken.borrowAmount, selectedToken.decimals)
        );
        console.log("Token:", selectedToken.symbol);
        console.log("User:", userIndex);

        // Borrow from pool (variable rate mode = 2)
        vm.broadcast(userKey);
        try
            pool.borrow(
                selectedToken.tokenAddress,
                selectedToken.borrowAmount,
                2,
                0,
                user
            )
        {
            successfulBorrows++;
            console.log(unicode"✅ Success");
        } catch Error(string memory reason) {
            console.log(unicode"❌ Failed:", reason);
        } catch {
            console.log(unicode"❌ Failed: Unknown error");
        }

        totalBorrows++;
    }

    function showFinalResults() internal view {
        console.log("");
        console.log("=======================================================");
        console.log(unicode"📊 COMPREHENSIVE SEEDING OPERATION COMPLETE!");
        console.log("=======================================================");
        console.log(unicode"🐋 WHALE SETUP:");
        console.log(
            unicode"   Account 0: Massive liquidity provided for all 12 tokens"
        );
        console.log("");
        console.log(unicode"📈 USER SUPPLIES:");
        console.log(unicode"   Total attempted:", totalSupplies);
        console.log(unicode"   Successful:", successfulSupplies);
        console.log(
            unicode"   Success rate:",
            (successfulSupplies * 100) / totalSupplies,
            "%"
        );
        console.log("");
        console.log(unicode"📉 USER BORROWS:");
        console.log(unicode"   Total attempted:", totalBorrows);
        console.log(unicode"   Successful:", successfulBorrows);
        console.log(
            unicode"   Success rate:",
            (successfulBorrows * 100) / totalBorrows,
            "%"
        );
        console.log("");
        console.log(
            unicode"🎯 TOTAL OPERATIONS:",
            totalSupplies + totalBorrows
        );
        console.log(
            unicode"✅ TOTAL SUCCESSFUL:",
            successfulSupplies + successfulBorrows
        );
        console.log("");
        console.log(unicode"🌟 Aave V3 local environment now has:");
        console.log(unicode"   • Whale-level liquidity in all 12 tokens");
        console.log(unicode"   • 100 realistic user positions");
        console.log(unicode"   • Comprehensive lending/borrowing ecosystem");
        console.log(
            unicode"   • Ready for advanced debt purchasing scenarios!"
        );
    }

    // Helper functions
    function formatAmount(
        uint256 amount,
        uint8 decimals
    ) internal pure returns (string memory) {
        if (decimals == 18) {
            return
                string(
                    abi.encodePacked(
                        uint2str(amount / 1e18),
                        ".",
                        uint2str((amount % 1e18) / 1e17)
                    )
                );
        } else if (decimals == 8) {
            return
                string(
                    abi.encodePacked(
                        uint2str(amount / 1e8),
                        ".",
                        uint2str((amount % 1e8) / 1e7)
                    )
                );
        } else if (decimals == 6) {
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
}
