#!/bin/bash

echo "🚀 Deploying PRODUCTION Aave V3 to Local Ganache"
echo "================================================"
echo "🎯 Using MainnetAccurateAaveV3Deploy with all 12 tokens"
echo ""

# Check if ganache is running
if ! curl -s http://localhost:8545 > /dev/null; then
    echo "❌ Error: Ganache is not running on localhost:8545"
    echo "Please start ganache first with: ./ganache-setup.sh"
    exit 1
fi

# Local settings - will use the first account from ganache-cli
LOCAL_RPC_URL="http://localhost:8545"

# Default private key for deterministic mnemonic "test test test..."
# Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
LOCAL_PRIVATE_KEY="${DEPLOYER_PRIVATE_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}"

# Export for the script
export DEPLOYER_PRIVATE_KEY=$LOCAL_PRIVATE_KEY

echo "🔗 RPC URL: $LOCAL_RPC_URL"
echo "🔑 Deployer: $(cast wallet address $LOCAL_PRIVATE_KEY 2>/dev/null || echo "Account #0 from deterministic ganache")"
echo ""

# Check balance
echo "💰 Checking deployer balance..."
BALANCE=$(cast balance $(cast wallet address $LOCAL_PRIVATE_KEY) --rpc-url $LOCAL_RPC_URL | head -n1)
echo "Balance: $BALANCE"

if [[ "$BALANCE" == "0" ]]; then
    echo "❌ Error: Deployer account has no ETH. Make sure ganache is running with funded accounts."
    exit 1
fi

echo ""
echo "🚀 Starting deployment..."
echo ""

forge script script/deploy-aavev3-sepolia/ComprehensiveAaveV3Deploy.sol:MainnetAccurateAaveV3Deploy \
    --rpc-url $LOCAL_RPC_URL \
    --private-key $LOCAL_PRIVATE_KEY \
    --broadcast \
    --via-ir \
    --gas-limit 150000000 \
    --optimize \
    --optimizer-runs 200 \
    -vv

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! PRODUCTION Aave V3 deployed to Local Ganache"
    echo "========================================================"
    echo ""
    
    # Extract important contract addresses
    echo "📍 EXTRACTING CONTRACT ADDRESSES..."
    echo ""
    
    # Get PoolAddressesProvider address
    POOL_ADDRESSES_PROVIDER=$(grep -A2 -B2 "PoolAddressesProvider" broadcast/ComprehensiveAaveV3Deploy.sol/1337/run-latest.json | grep "contractAddress" | head -1 | sed 's/.*"contractAddress": "\([^"]*\)".*/\1/')
    
    if [ -n "$POOL_ADDRESSES_PROVIDER" ]; then
        echo "🏛️  PoolAddressesProvider: $POOL_ADDRESSES_PROVIDER"
        
        # Get actual Pool proxy address from PoolAddressesProvider
        POOL_PROXY=$(cast call $POOL_ADDRESSES_PROVIDER "getPool()" --rpc-url $LOCAL_RPC_URL | sed 's/^0x//' | sed 's/^0*//' | awk '{print "0x" tolower($0)}')
        
        if [ -n "$POOL_PROXY" ] && [ "$POOL_PROXY" != "0x0" ]; then
            echo "🏊 Pool Proxy (REAL):     $POOL_PROXY"
        else
            echo "⚠️  Could not retrieve Pool proxy address"
        fi
        
        # Get PoolConfigurator proxy address
        POOL_CONFIGURATOR_PROXY=$(cast call $POOL_ADDRESSES_PROVIDER "getPoolConfigurator()" --rpc-url $LOCAL_RPC_URL | sed 's/^0x//' | sed 's/^0*//' | awk '{print "0x" tolower($0)}')
        
        if [ -n "$POOL_CONFIGURATOR_PROXY" ] && [ "$POOL_CONFIGURATOR_PROXY" != "0x0" ]; then
            echo "⚙️  PoolConfigurator Proxy: $POOL_CONFIGURATOR_PROXY"
        fi
        
        # Get ACLManager address
        ACL_MANAGER=$(cast call $POOL_ADDRESSES_PROVIDER "getACLManager()" --rpc-url $LOCAL_RPC_URL | sed 's/^0x//' | sed 's/^0*//' | awk '{print "0x" tolower($0)}')
        
        if [ -n "$ACL_MANAGER" ] && [ "$ACL_MANAGER" != "0x0" ]; then
            echo "🔐 ACLManager:            $ACL_MANAGER"
        fi
        
        # Get Oracle address
        ORACLE=$(cast call $POOL_ADDRESSES_PROVIDER "getPriceOracle()" --rpc-url $LOCAL_RPC_URL | sed 's/^0x//' | sed 's/^0*//' | awk '{print "0x" tolower($0)}')
        
        if [ -n "$ORACLE" ] && [ "$ORACLE" != "0x0" ]; then
            echo "🔮 Oracle:                $ORACLE"
        fi
        
        echo ""
        echo "📋 COPY-PASTE READY ADDRESSES:"
        echo "=============================="
        echo "Pool:                     $POOL_PROXY"
        echo "PoolAddressesProvider:    $POOL_ADDRESSES_PROVIDER"
        echo "PoolConfigurator:         $POOL_CONFIGURATOR_PROXY"
        echo "ACLManager:               $ACL_MANAGER"
        echo "Oracle:                   $ORACLE"
        echo ""
    else
        echo "⚠️  Could not extract PoolAddressesProvider address from deployment logs"
    fi
    
    echo "✅ Deployed with REAL mainnet accuracy:"
    echo "   • All 12 tokens with actual mainnet LTV/liquidation parameters"
    echo "   • Current market prices ($2,563 WETH, $42,826 WBTC, etc.)"
    echo "   • AAVE borrowing disabled (production-accurate)"
    echo "   • Conservative stablecoin settings (77% LTV)"
    echo "   • Ultra-conservative CRV settings (35% LTV)"
    echo "   • Realistic interest rate curves"
    echo ""
    echo "🔧 Available for comprehensive testing:"
    echo "   • Use the accounts displayed by ganache-cli output"
    echo "   • Account #0: Deployer (used for deployment)"
    echo "   • Account #1-9: Available for testing"
    echo "   • RPC URL: http://localhost:8545"
    echo "   • Network ID: 1337 (default)"
    echo ""
    echo "📊 Ready for production-level testing:"
    echo "   1. Test real Health Factor scenarios"
    echo "   2. Test debt purchasing with actual market conditions"
    echo "   3. Dynamic oracle price updates with: ./scripts-utils/update_prices.sh"
    echo "   4. Interact with Aave using: ./scripts-utils/interact_with_aave.sh"
    echo ""
else
    echo ""
    echo "❌ PRODUCTION DEPLOYMENT FAILED!"
    echo "Please check the error messages above."
    echo ""
    echo "💡 Common issues:"
    echo "   • Ganache not running: ./ganache-setup.sh"
    echo "   • Wrong private key: Use Account #0 private key from ganache-cli output"
    echo "   • Insufficient gas limit"
    echo "   • Contract compilation errors"
    echo "   • Import path issues (check foundry.toml remappings)"
    echo ""
    echo "🔧 If private key doesn't match, set it manually:"
    echo "   export DEPLOYER_PRIVATE_KEY=0x[your-account-0-private-key]"
    echo "   ./deploy_production_aave_v3_local.sh"
    exit 1
fi 