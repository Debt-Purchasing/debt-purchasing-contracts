#!/bin/bash

echo "🔮 Updating Oracle Prices on Local Anvil"
echo "========================================="
echo "📊 Reading prices from prices.json..."
echo ""

# Navigate to project root first (detect where we are)
# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Navigate to project root
cd "$PROJECT_ROOT"

# Load environment variables from .env.local
if [ ! -f ".env.local" ]; then
    echo "❌ Error: .env.local file not found"
    echo "Please run ./scripts-utils/local/deploy_aave_v3_local.sh first"
    exit 1
fi

source .env.local

# Check if prices.json exists
if [ ! -f "scripts-utils/prices.json" ]; then
    echo "❌ Error: scripts-utils/prices.json not found"
    echo "Please run ./scripts-utils/fetch_prices.sh first"
    exit 1
fi

# Check if anvil is running
if ! curl -s ${LOCAL_RPC_URL}:${PORT} > /dev/null; then
    echo "❌ Error: Anvil is not running on ${LOCAL_RPC_URL}:${PORT}"
    echo "Please start anvil first with: ./scripts-utils/local/start_anvil.sh"
    exit 1
fi

# Check if OracleManager is deployed
if [ -z "$ORACLE_MANAGER" ]; then
    echo "❌ Error: ORACLE_MANAGER address not found in .env.local"
    echo "Please redeploy with: ./scripts-utils/local/deploy_aave_v3_local.sh"
    exit 1
fi

echo "🔮 Oracle Manager: $ORACLE_MANAGER"
echo "🌐 RPC URL: ${LOCAL_RPC_URL}:${PORT}"
echo ""

# Token order must match deployment order: WETH, wstETH, WBTC, USDC, DAI, LINK, AAVE, cbETH, USDT, rETH, LUSD, CRV
TOKEN_ORDER=("WETH" "wstETH" "WBTC" "USDC" "DAI" "LINK" "AAVE" "cbETH" "USDT" "rETH" "LUSD" "CRV")

# Corresponding oracle environment variables
ORACLE_VARS=("WETH_ORACLE" "WSTETH_ORACLE" "WBTC_ORACLE" "USDC_ORACLE" "DAI_ORACLE" "LINK_ORACLE" "AAVE_TOKEN_ORACLE" "CBETH_ORACLE" "USDT_ORACLE" "RETH_ORACLE" "LUSD_ORACLE" "CRV_ORACLE")

# Arrays to store oracle addresses and prices
ORACLE_ADDRESSES=()
PRICES=()

echo "📊 Extracting prices and oracle addresses..."
echo ""

# Extract prices and oracle addresses in correct order
for i in "${!TOKEN_ORDER[@]}"; do
    TOKEN="${TOKEN_ORDER[$i]}"
    ORACLE_VAR="${ORACLE_VARS[$i]}"
    
    # Get price from prices.json
    PRICE=$(jq -r ".[] | select(.token == \"$TOKEN\") | .price" scripts-utils/prices.json)
    
    if [ "$PRICE" == "null" ] || [ -z "$PRICE" ]; then
        echo "❌ Error: Price not found for token $TOKEN in prices.json"
        exit 1
    fi
    
    # Get oracle address from environment
    ORACLE_ADDRESS=$(eval echo "\$$ORACLE_VAR")
    
    if [ -z "$ORACLE_ADDRESS" ]; then
        echo "❌ Error: Oracle address not found for $ORACLE_VAR in .env.local"
        exit 1
    fi
    
    ORACLE_ADDRESSES+=("$ORACLE_ADDRESS")
    PRICES+=("$PRICE")
    
    echo "✅ $TOKEN: $PRICE (Oracle: $ORACLE_ADDRESS)"
done

echo ""
echo "🚀 Calling updatePrices() on OracleManager..."
echo "📊 Updating ${#ORACLE_ADDRESSES[@]} oracle prices..."

# Call updatePrices function
echo "⚡ Executing transaction..."

# Use a simpler approach - create temp file for arrays
ORACLE_ARRAY_FORMATTED=""
PRICE_ARRAY_FORMATTED=""

for i in "${!ORACLE_ADDRESSES[@]}"; do
    if [ $i -gt 0 ]; then
        ORACLE_ARRAY_FORMATTED="${ORACLE_ARRAY_FORMATTED},"
        PRICE_ARRAY_FORMATTED="${PRICE_ARRAY_FORMATTED},"
    fi
    ORACLE_ARRAY_FORMATTED="${ORACLE_ARRAY_FORMATTED}${ORACLE_ADDRESSES[$i]}"
    PRICE_ARRAY_FORMATTED="${PRICE_ARRAY_FORMATTED}${PRICES[$i]}"
done

echo "🔗 Oracle addresses: [$ORACLE_ARRAY_FORMATTED]"
echo "💰 Prices: [$PRICE_ARRAY_FORMATTED]"
echo ""

TX_HASH=$(cast send $ORACLE_MANAGER \
    "updatePrices(address[],uint256[])" \
    "[$ORACLE_ARRAY_FORMATTED]" \
    "[$PRICE_ARRAY_FORMATTED]" \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --rpc-url ${LOCAL_RPC_URL}:${PORT} \
    2>&1)

if [ $? -eq 0 ]; then
    echo "✅ SUCCESS! Oracle prices updated"
    echo "📋 Transaction hash: $TX_HASH"
    echo ""
    
    # Verify prices were updated by reading a few oracles
    echo "🔍 Verifying price updates..."
    for i in 0 2 3; do  # Check WETH, WBTC, USDC
        TOKEN="${TOKEN_ORDER[$i]}"
        ORACLE_ADDRESS="${ORACLE_ADDRESSES[$i]}"
        EXPECTED_PRICE="${PRICES[$i]}"
        
        ACTUAL_PRICE=$(cast call $ORACLE_ADDRESS "latestAnswer()" --rpc-url ${LOCAL_RPC_URL}:${PORT})
        # Convert hex to decimal
        ACTUAL_PRICE_DEC=$(printf "%d" $ACTUAL_PRICE)
        
        if [ "$ACTUAL_PRICE_DEC" == "$EXPECTED_PRICE" ]; then
            echo "✅ $TOKEN: $ACTUAL_PRICE_DEC (verified)"
        else
            echo "⚠️  $TOKEN: Expected $EXPECTED_PRICE, got $ACTUAL_PRICE_DEC"
        fi
    done
    echo ""
    echo "🎉 Oracle price update completed successfully!"
    echo "💡 All ${#ORACLE_ADDRESSES[@]} token prices have been updated with latest market data"
    
else
    echo "❌ ERROR: Failed to update oracle prices"
    echo "💡 Check if OracleManager is properly deployed and you have permission to update prices"
    exit 1
fi 