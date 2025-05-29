#!/bin/bash

echo "🚀 Deploying PRODUCTION Aave V3 to Sepolia Testnet"
echo "================================================="
echo "🎯 Using MainnetAccurateAaveV3Deploy with all 12 tokens"
echo ""

# Check required environment variables
if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo "❌ Error: SEPOLIA_RPC_URL not set"
    echo "Please set: export SEPOLIA_RPC_URL=https://your-sepolia-rpc-url"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set"
    echo "Please set: export PRIVATE_KEY=0x..."
    exit 1
fi

echo "✅ Environment variables configured"
echo "📡 RPC URL: $SEPOLIA_RPC_URL"
echo "🔑 Using provided private key for deployment"

echo ""
echo "📋 PRODUCTION Configuration Features:"
echo "   • 🪙 All 12 mainnet tokens: WETH, wstETH, WBTC, USDC, DAI, LINK, AAVE, cbETH, USDT, rETH, LUSD, CRV"
echo "   • 📊 Real mainnet parameters (LTV, liquidation thresholds, etc.)"
echo "   • 💰 Current market prices from mainnet analysis"
echo "   • 🏦 AAVE borrowing DISABLED (as per real mainnet)"
echo "   • 🔒 Conservative stablecoin LTV (77% instead of 86%)"
echo "   • 📈 Realistic interest rate strategies"
echo "   • 🔧 Dynamic updateable Chainlink-compatible oracles"
echo ""

echo "🔨 Starting production deployment to Sepolia..."

forge script script/deploy-aavev3-sepolia/ComprehensiveAaveV3Deploy.sol:MainnetAccurateAaveV3Deploy \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --via-ir \
    --gas-limit 30000000 \
    --optimize \
    --optimizer-runs 200 \
    -vvv

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! PRODUCTION Aave V3 deployed to Sepolia"
    echo "================================================="
    echo ""
    echo "✅ Deployed with REAL mainnet accuracy:"
    echo "   • All 12 tokens with actual mainnet LTV/liquidation parameters"
    echo "   • Current market prices ($2,563 WETH, $42,826 WBTC, etc.)"
    echo "   • AAVE borrowing disabled (production-accurate)"
    echo "   • Conservative stablecoin settings (77% LTV)"
    echo "   • Ultra-conservative CRV settings (35% LTV)"
    echo "   • Realistic interest rate curves"
    echo ""
    echo "📊 Ready for production-level testing on Sepolia:"
    echo "   1. Test real Health Factor scenarios"
    echo "   2. Test debt purchasing with actual market conditions"
    echo "   3. Dynamic oracle price updates"
    echo "   4. Full AaveRouter integration"
    echo ""
    echo "💡 Next steps:"
    echo "   • Save the deployed contract addresses"
    echo "   • Update your frontend/backend with new addresses"
    echo "   • Test with the utility scripts (adapted for Sepolia)"
    echo ""
else
    echo ""
    echo "❌ PRODUCTION DEPLOYMENT TO SEPOLIA FAILED!"
    echo "Please check the error messages above."
    echo ""
    echo "💡 Common issues:"
    echo "   • Invalid RPC URL or network issues"
    echo "   • Insufficient ETH for gas fees"
    echo "   • Private key issues"
    echo "   • Contract compilation errors"
    exit 1
fi 