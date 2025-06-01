#!/bin/bash

echo "🚀 Deploying PRODUCTION Aave V3 to Sepolia"
echo "================================================"
echo "🎯 Using MainnetAccurateAaveV3Deploy with all 12 tokens"
echo ""

# Navigate to project root first (detect where we are)
# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Navigate to project root
cd "$PROJECT_ROOT"

# Load existing environment variables from .env.sepolia if it exists
if [ -f ".env.sepolia" ]; then
    source .env.sepolia
else
    echo "⚠️  No existing .env.sepolia found, will create new one"
fi

# Use environment variables or defaults
SEPOLIA_RPC_URL="${SEPOLIA_RPC_URL}"
CHAIN_ID="${CHAIN_ID}"

echo ""
# Default private key for deterministic mnemonic "test test test..."
DEPLOYER_PRIVATE_KEY="${DEPLOYER_PRIVATE_KEY}"

# Export for the script
export DEPLOYER_PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY

# Check balance
BALANCE=$(cast balance $(cast wallet address $DEPLOYER_PRIVATE_KEY) --rpc-url $SEPOLIA_RPC_URL | head -n1)

if [[ "$BALANCE" == "0" ]]; then
    echo "❌ Error: Deployer account has no ETH"
    exit 1
fi

echo ""
echo "🚀 Starting deployment..."
echo ""

DEPLOYMENT_SUCCESS=false
    
forge script ./script/for-testing/ComprehensiveAaveV3Deploy.sol:MainnetAccurateAaveV3Deploy \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --via-ir \
    --gas-limit 150000000 \
    --optimize \
    --optimizer-runs 200 \
    -vv \
    # --broadcast 

if [ $? -eq 0 ]; then
    DEPLOYMENT_SUCCESS=true
else
    DEPLOYMENT_SUCCESS=false
fi

if [ "$DEPLOYMENT_SUCCESS" = true ]; then
    echo ""
    echo "🎉 SUCCESS! PRODUCTION Aave V3 deployed to Sepolia"
    echo "========================================================"
    echo ""
    
    # Get PoolAddressesProvider address
    POOL_ADDRESSES_PROVIDER=$(grep -A2 -B2 "PoolAddressesProvider" broadcast/ComprehensiveAaveV3Deploy.sol/${CHAIN_ID}/run-latest.json | grep "contractAddress" | head -1 | sed 's/.*"contractAddress": "\([^"]*\)".*/\1/')
    
    if [ -n "$POOL_ADDRESSES_PROVIDER" ]; then
        
        # Get actual Pool proxy address from PoolAddressesProvider
        POOL_PROXY=$(cast call $POOL_ADDRESSES_PROVIDER "getPool()" --rpc-url $SEPOLIA_RPC_URL | sed 's/^0x//' | sed 's/^0*//' | awk '{print "0x" tolower($0)}')
        
        # Get PoolConfigurator proxy address
        POOL_CONFIGURATOR_PROXY=$(cast call $POOL_ADDRESSES_PROVIDER "getPoolConfigurator()" --rpc-url $SEPOLIA_RPC_URL | sed 's/^0x//' | sed 's/^0*//' | awk '{print "0x" tolower($0)}')
        
        # Get ACLManager address
        ACL_MANAGER=$(cast call $POOL_ADDRESSES_PROVIDER "getACLManager()" --rpc-url $SEPOLIA_RPC_URL | sed 's/^0x//' | sed 's/^0*//' | awk '{print "0x" tolower($0)}')
        
        # Get Oracle address
        ORACLE=$(cast call $POOL_ADDRESSES_PROVIDER "getPriceOracle()" --rpc-url $SEPOLIA_RPC_URL | sed 's/^0x//' | sed 's/^0*//' | awk '{print "0x" tolower($0)}')
         
        # Create backup of .env.sepolia
        if [ -f ".env.sepolia" ]; then
            cp .env.sepolia .env.sepolia.backup
        fi
        
        # Update or create .env.sepolia with all addresses
        if [ -f ".env.sepolia" ]; then
            # Update core addresses
            sed -i.tmp "s/^POOL_ADDRESSES_PROVIDER=.*/POOL_ADDRESSES_PROVIDER=${POOL_ADDRESSES_PROVIDER}/" .env.sepolia
            sed -i.tmp "s/^POOL_PROXY=.*/POOL_PROXY=${POOL_PROXY}/" .env.sepolia
            sed -i.tmp "s/^POOL_CONFIGURATOR_PROXY=.*/POOL_CONFIGURATOR_PROXY=${POOL_CONFIGURATOR_PROXY}/" .env.sepolia
            sed -i.tmp "s/^ACL_MANAGER=.*/ACL_MANAGER=${ACL_MANAGER}/" .env.sepolia
            sed -i.tmp "s/^AAVE_ORACLE=.*/AAVE_ORACLE=${ORACLE}/" .env.sepolia
            
        else
            echo "⚠️  .env.sepolia file not found. Creating new one..."
        fi
        
        # Function to get token emoji
        get_token_emoji() {
            case "$1" in
                "WETH"|"wstETH") echo "🟡" ;;
                "WBTC") echo "🟠" ;;
                "USDC") echo "🔵" ;;
                "DAI"|"USDT") echo "🟢" ;;
                "LINK") echo "🔗" ;;
                "AAVE") echo "👻" ;;
                "cbETH") echo "🔷" ;;
                "rETH") echo "🔴" ;;
                "LUSD") echo "💰" ;;
                "CRV") echo "🌊" ;;
                *) echo "🔸" ;;
            esac
        }
                
        # Extract addresses into array to avoid subshell issues (same as oracle approach)
        TOKEN_ADDRESSES=()
        while IFS= read -r line; do
            address=$(echo "$line" | grep -o '"0x[a-fA-F0-9]*"' | tr -d '"')
            if [ -n "$address" ]; then
                TOKEN_ADDRESSES+=("$address")
            fi
        done < <(grep -A1 '"contractName": "SimpleERC20"' broadcast/ComprehensiveAaveV3Deploy.sol/${CHAIN_ID}/run-latest.json | grep '"contractAddress"')
        
        # Process each token address
        for address in "${TOKEN_ADDRESSES[@]}"; do
            # Try to get token symbol by calling the contract
            raw_symbol=$(cast call $address "symbol()" --rpc-url $SEPOLIA_RPC_URL 2>/dev/null | cast to-ascii 2>/dev/null | tr -d '\0' || echo "")
            
            # Trim leading/trailing spaces
            symbol=$(echo "$raw_symbol" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            if [ -n "$symbol" ]; then                
                # Update in .env.sepolia based on symbol
                case "$symbol" in
                    "WETH") sed -i.tmp "s/^WETH_ADDRESS=.*/WETH_ADDRESS=${address}/" .env.sepolia ;;
                    "wstETH") sed -i.tmp "s/^WSTETH_ADDRESS=.*/WSTETH_ADDRESS=${address}/" .env.sepolia ;;
                    "WBTC") sed -i.tmp "s/^WBTC_ADDRESS=.*/WBTC_ADDRESS=${address}/" .env.sepolia ;;
                    "USDC") sed -i.tmp "s/^USDC_ADDRESS=.*/USDC_ADDRESS=${address}/" .env.sepolia ;;
                    "DAI") sed -i.tmp "s/^DAI_ADDRESS=.*/DAI_ADDRESS=${address}/" .env.sepolia ;;
                    "LINK") sed -i.tmp "s/^LINK_ADDRESS=.*/LINK_ADDRESS=${address}/" .env.sepolia ;;
                    "AAVE") sed -i.tmp "s/^AAVE_ADDRESS=.*/AAVE_ADDRESS=${address}/" .env.sepolia ;;
                    "cbETH") sed -i.tmp "s/^CBETH_ADDRESS=.*/CBETH_ADDRESS=${address}/" .env.sepolia ;;
                    "USDT") sed -i.tmp "s/^USDT_ADDRESS=.*/USDT_ADDRESS=${address}/" .env.sepolia ;;
                    "rETH") sed -i.tmp "s/^RETH_ADDRESS=.*/RETH_ADDRESS=${address}/" .env.sepolia ;;
                    "LUSD") sed -i.tmp "s/^LUSD_ADDRESS=.*/LUSD_ADDRESS=${address}/" .env.sepolia ;;
                    "CRV") sed -i.tmp "s/^CRV_ADDRESS=.*/CRV_ADDRESS=${address}/" .env.sepolia ;;
                esac
            fi
        done
        
        # Extract oracle addresses into array to avoid subshell issues
        ORACLE_ADDRESSES=()
        while IFS= read -r line; do
            address=$(echo "$line" | grep -o '"0x[a-fA-F0-9]*"' | tr -d '"')
            if [ -n "$address" ]; then
                ORACLE_ADDRESSES+=("$address")
            fi
        done < <(grep -A1 '"contractName": "ChainlinkMockAggregator"' broadcast/ComprehensiveAaveV3Deploy.sol/${CHAIN_ID}/run-latest.json | grep '"contractAddress"')
        
        # Since oracles are deployed in the same order as tokens, match them by index
        # Token order: WETH, wstETH, WBTC, USDC, DAI, LINK, AAVE, cbETH, USDT, rETH, LUSD, CRV
        TOKEN_SYMBOLS=("WETH" "wstETH" "WBTC" "USDC" "DAI" "LINK" "AAVE" "cbETH" "USDT" "rETH" "LUSD" "CRV")
        
        # Process each oracle address with corresponding token symbol
        for i in "${!ORACLE_ADDRESSES[@]}"; do
            address="${ORACLE_ADDRESSES[$i]}"
            
            # Get token symbol from the same deployment order
            if [ $i -lt ${#TOKEN_SYMBOLS[@]} ]; then
                token_symbol="${TOKEN_SYMBOLS[$i]}"                
                # Update in .env.sepolia based on token symbol
                case "$token_symbol" in
                    "WETH") sed -i.tmp "s/^WETH_ORACLE=.*/WETH_ORACLE=${address}/" .env.sepolia ;;
                    "wstETH") sed -i.tmp "s/^WSTETH_ORACLE=.*/WSTETH_ORACLE=${address}/" .env.sepolia ;;
                    "WBTC") sed -i.tmp "s/^WBTC_ORACLE=.*/WBTC_ORACLE=${address}/" .env.sepolia ;;
                    "USDC") sed -i.tmp "s/^USDC_ORACLE=.*/USDC_ORACLE=${address}/" .env.sepolia ;;
                    "DAI") sed -i.tmp "s/^DAI_ORACLE=.*/DAI_ORACLE=${address}/" .env.sepolia ;;
                    "LINK") sed -i.tmp "s/^LINK_ORACLE=.*/LINK_ORACLE=${address}/" .env.sepolia ;;
                    "AAVE") sed -i.tmp "s/^AAVE_TOKEN_ORACLE=.*/AAVE_TOKEN_ORACLE=${address}/" .env.sepolia ;;
                    "cbETH") sed -i.tmp "s/^CBETH_ORACLE=.*/CBETH_ORACLE=${address}/" .env.sepolia ;;
                    "USDT") sed -i.tmp "s/^USDT_ORACLE=.*/USDT_ORACLE=${address}/" .env.sepolia ;;
                    "rETH") sed -i.tmp "s/^RETH_ORACLE=.*/RETH_ORACLE=${address}/" .env.sepolia ;;
                    "LUSD") sed -i.tmp "s/^LUSD_ORACLE=.*/LUSD_ORACLE=${address}/" .env.sepolia ;;
                    "CRV") sed -i.tmp "s/^CRV_ORACLE=.*/CRV_ORACLE=${address}/" .env.sepolia ;;
                esac
            fi
        done
        
        # Clean up temp files
        rm -rf .env.sepolia.tmp
       
        echo "✅ All addresses automatically saved to .env.sepolia"
        echo "📁 Backup saved as: .env.sepolia.backup"
        echo ""
        
        # Extract OracleManager address from main deployment
        ORACLE_MANAGER_ADDRESS=$(grep -A1 '"contractName": "OracleManager"' broadcast/ComprehensiveAaveV3Deploy.sol/${CHAIN_ID}/run-latest.json | grep '"contractAddress"' | sed 's/.*"contractAddress": "\([^"]*\)".*/\1/')
        
        if [ -n "$ORACLE_MANAGER_ADDRESS" ]; then
            echo "✅ OracleManager deployed at: $ORACLE_MANAGER_ADDRESS"
            
            # Update .env.sepolia with OracleManager address
            if grep -q "^ORACLE_MANAGER=" .env.sepolia; then
                sed -i.tmp "s/^ORACLE_MANAGER=.*/ORACLE_MANAGER=${ORACLE_MANAGER_ADDRESS}/" .env.sepolia
            else
                echo "ORACLE_MANAGER=${ORACLE_MANAGER_ADDRESS}" >> .env.sepolia
            fi
            
            rm -f .env.sepolia.tmp
            echo "✅ OracleManager address saved to .env.sepolia"
            echo ""
        else
            echo "⚠️  Could not extract OracleManager address from deployment logs"
        fi
        
    else
        echo "⚠️  Could not extract PoolAddressesProvider address from deployment logs"
    fi
else
    echo ""
    echo "❌ PRODUCTION DEPLOYMENT FAILED!"
    exit 1
fi 