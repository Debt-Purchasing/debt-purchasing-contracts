#!/bin/bash

echo "🏦 MULTI-USER AAVE V3 LENDING & BORROWING TEST"
echo "=============================================="
echo "🎭 Testing realistic multi-user scenario with:"
echo "   • 5 users with different strategies"
echo "   • Multiple assets (WETH, USDC)" 
echo "   • Natural liquidity provisioning"
echo "   • No manual reserve minting needed"
echo ""

# Settings
LOCAL_RPC_URL="http://localhost:8545"
LOCAL_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Check if ganache is running
if ! curl -s http://localhost:8545 > /dev/null; then
    echo "❌ Error: Ganache is not running on localhost:8545"
    echo "Please start ganache first with: ./ganache-setup.sh"
    exit 1
fi

echo "🔗 RPC URL: $LOCAL_RPC_URL"
echo "🔑 Using deterministic ganache accounts (Account #0-4)"
echo ""

echo "🚀 Running multi-user testing scenario..."
echo ""

forge script script/DebugLendingBorrowing.sol:DebugLendingBorrowing \
    --rpc-url $LOCAL_RPC_URL \
    --private-key $LOCAL_PRIVATE_KEY \
    --broadcast \
    --via-ir \
    --gas-limit 30000000 \
    --optimize \
    --optimizer-runs 200 \
    -vvv

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! Multi-user testing completed"
    echo "========================================"
    echo ""
    echo "✅ What was tested:"
    echo "   • 5 different user strategies"
    echo "   • Whale depositor (50 WETH)"
    echo "   • Stablecoin lender (100k USDC)"
    echo "   • Balanced trader (20 WETH)"
    echo "   • Conservative institution (50k USDC)"
    echo "   • Retail user (10 WETH)"
    echo ""
    echo "💡 Market dynamics created:"
    echo "   • Natural liquidity in both WETH and USDC"
    echo "   • Cross-asset borrowing opportunities"
    echo "   • Realistic Health Factor scenarios"
    echo "   • No manual reserve pre-funding needed"
    echo ""
    echo "🔧 Next steps:"
    echo "   • Check user positions and aToken balances"
    echo "   • Test debt purchasing scenarios"
    echo "   • Integrate with AaveRouter.sol"
    echo ""
else
    echo ""
    echo "❌ MULTI-USER TEST FAILED!"
    echo "Please check the error messages above."
    echo ""
    echo "💡 Common issues:"
    echo "   • Wrong contract addresses (run deployment first)"
    echo "   • PoolAddressesProvider address needs updating"
    echo "   • Token addresses need updating from latest deployment"
    echo ""
    echo "🔧 To get latest addresses:"
    echo "   ./deploy_production_aave_v3_local.sh"
    echo "   # Copy the addresses to DebugLendingBorrowing.sol"
    exit 1
fi 