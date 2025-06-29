#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================================${NC}"
echo -e "${CYAN}🌾 SEEDING AAVE V3 LOCAL WITH WHALE + 100 USERS${NC}"
echo -e "${BLUE}=======================================================${NC}"
echo ""

# Check if .env.local exists
if [ ! -f .env.local ]; then
    echo -e "${RED}❌ Error: .env.local not found!${NC}"
    echo -e "${YELLOW}💡 Please run deploy_aave_v3_local.sh first to create environment${NC}"
    exit 1
fi

# Load environment variables
echo -e "${YELLOW}📋 Loading environment variables...${NC}"
source .env.local

# Export all variables for forge script
export LOCAL_RPC_URL
export PORT
export CHAIN_ID
export DEPLOYER_PRIVATE_KEY
export POOL_ADDRESSES_PROVIDER
export POOL_PROXY
export POOL_CONFIGURATOR_PROXY
export ACL_MANAGER
export AAVE_ORACLE
export WETH_ADDRESS
export WSTETH_ADDRESS
export WBTC_ADDRESS
export USDC_ADDRESS
export DAI_ADDRESS
export LINK_ADDRESS
export AAVE_ADDRESS
export CBETH_ADDRESS
export USDT_ADDRESS
export RETH_ADDRESS
export LUSD_ADDRESS
export CRV_ADDRESS

# Validate required environment variables
required_vars=(
    "LOCAL_RPC_URL"
    "PORT"
    "POOL_ADDRESSES_PROVIDER" 
    "POOL_PROXY"
    "WETH_ADDRESS"
    "WSTETH_ADDRESS"
    "WBTC_ADDRESS"
    "USDC_ADDRESS"
    "DAI_ADDRESS"
    "LINK_ADDRESS"
    "AAVE_ADDRESS"
    "CBETH_ADDRESS"
    "USDT_ADDRESS"
    "RETH_ADDRESS"
    "LUSD_ADDRESS"
    "CRV_ADDRESS"
)

echo -e "${YELLOW}🔍 Validating environment variables...${NC}"
missing_vars=()

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo -e "${RED}❌ Missing required environment variables:${NC}"
    for var in "${missing_vars[@]}"; do
        echo -e "${RED}   - $var${NC}"
    done
    echo -e "${YELLOW}💡 Please ensure deploy_aave_v3_local.sh completed successfully${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All environment variables validated${NC}"
echo ""

# Show configuration
echo -e "${PURPLE}⚙️  SEEDING CONFIGURATION${NC}"
echo -e "${CYAN}================================${NC}"
echo -e "${YELLOW}🌐 RPC URL:${NC} $LOCAL_RPC_URL:${PORT}"
echo -e "${YELLOW}🏊 Pool:${NC} $POOL_PROXY"
echo -e "${YELLOW}🏛️ Provider:${NC} $POOL_ADDRESSES_PROVIDER"
echo ""
echo -e "${YELLOW}🪙 TOKEN ADDRESSES:${NC}"
echo -e "${CYAN}   WETH:${NC} $WETH_ADDRESS"
echo -e "${CYAN}   wstETH:${NC} $WSTETH_ADDRESS"
echo -e "${CYAN}   WBTC:${NC} $WBTC_ADDRESS"
echo -e "${CYAN}   USDC:${NC} $USDC_ADDRESS"
echo -e "${CYAN}   DAI:${NC} $DAI_ADDRESS"
echo -e "${CYAN}   LINK:${NC} $LINK_ADDRESS"
echo -e "${CYAN}   AAVE:${NC} $AAVE_ADDRESS"
echo -e "${CYAN}   cbETH:${NC} $CBETH_ADDRESS"
echo -e "${CYAN}   USDT:${NC} $USDT_ADDRESS"
echo -e "${CYAN}   rETH:${NC} $RETH_ADDRESS"
echo -e "${CYAN}   LUSD:${NC} $LUSD_ADDRESS"
echo -e "${CYAN}   CRV:${NC} $CRV_ADDRESS"
echo ""

# Check if Anvil is running
echo -e "${YELLOW}🔍 Checking if Anvil is running...${NC}"
if ! curl -s -X POST \
    -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' \
    $LOCAL_RPC_URL:$PORT > /dev/null 2>&1; then
    echo -e "${RED}❌ Anvil is not running on $LOCAL_RPC_URL:$PORT${NC}"
    echo -e "${YELLOW}💡 Please start Anvil with: ./scripts-utils/local/start_anvil.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Anvil is running and responding${NC}"
echo ""

# Check if Pool is deployed
echo -e "${YELLOW}🔍 Verifying Pool deployment...${NC}"
if ! cast code $POOL_PROXY --rpc-url $LOCAL_RPC_URL:$PORT | grep -q "0x" || [ "$(cast code $POOL_PROXY --rpc-url $LOCAL_RPC_URL:$PORT)" = "0x" ]; then
    echo -e "${RED}❌ Pool contract not deployed at $POOL_PROXY${NC}"
    echo -e "${YELLOW}💡 Please run deploy_aave_v3_local.sh first${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Pool contract verified at $POOL_PROXY${NC}"
echo ""

# Execute the seeding script
echo -e "${BLUE}🚀 EXECUTING COMPREHENSIVE SEEDING OPERATION${NC}"
echo -e "${CYAN}===========================================${NC}"
echo ""

# Run the SeedLendingBorrowing contract (environment variables already exported)
echo -e "${YELLOW}📜 Running SeedLendingBorrowing.sol...${NC}"

if forge script script/for-testing/SeedLendingBorrowing.sol:SeedLendingBorrowing \
    --rpc-url $LOCAL_RPC_URL:$PORT \
    --broadcast \
    --gas-limit 50000000 \
    -vvv; then
    
    echo ""
    echo -e "${GREEN}=======================================================${NC}"
    echo -e "${GREEN}🎉 COMPREHENSIVE SEEDING OPERATION COMPLETED!${NC}"
    echo -e "${GREEN}=======================================================${NC}"
    echo ""
    echo -e "${CYAN}📊 SUMMARY:${NC}"
    echo -e "${YELLOW}🐋 WHALE SETUP (Account 0):${NC}"
    echo -e "${CYAN}   • Massive liquidity supplied for all 12 tokens${NC}"
    echo -e "${CYAN}   • 1000 WETH, 500 wstETH, 100 WBTC, 5M USDC, etc.${NC}"
    echo ""
    echo -e "${YELLOW}👥 USER OPERATIONS (Accounts 1-100):${NC}"
    echo -e "${CYAN}   • 100 supply operations with fixed amounts${NC}"
    echo -e "${CYAN}   • 100 borrow operations with conservative amounts${NC}"
    echo -e "${CYAN}   • Distributed across all 12 tokens${NC}"
    echo -e "${CYAN}   • No random amounts - fixed for price stability${NC}"
    echo ""
    echo -e "${YELLOW}🪙 TOKEN COVERAGE:${NC}"
    echo -e "${CYAN}   • ETH variants: WETH, wstETH, cbETH, rETH${NC}"
    echo -e "${CYAN}   • Bitcoin: WBTC${NC}"
    echo -e "${CYAN}   • Stablecoins: USDC, DAI, USDT, LUSD${NC}"
    echo -e "${CYAN}   • DeFi tokens: LINK, AAVE, CRV${NC}"
    echo ""
    echo -e "${GREEN}✅ Your local Aave V3 environment is now comprehensively seeded!${NC}"
    echo -e "${CYAN}💡 Ready for advanced debt purchasing scenarios with 101 accounts${NC}"
    
else
    echo ""
    echo -e "${RED}=======================================================${NC}"
    echo -e "${RED}❌ SEEDING OPERATION FAILED${NC}"
    echo -e "${RED}=======================================================${NC}"
    echo ""
    echo -e "${YELLOW}🔧 TROUBLESHOOTING TIPS:${NC}"
    echo -e "${CYAN}   1. Check if all tokens are properly deployed${NC}"
    echo -e "${CYAN}   2. Ensure sufficient gas limit (increased to 50M)${NC}"
    echo -e "${CYAN}   3. Verify Pool configuration is correct${NC}"
    echo -e "${CYAN}   4. Check Anvil logs for specific errors${NC}"
    echo -e "${CYAN}   5. Ensure anvil is configured for 101 accounts${NC}"
    echo -e "${CYAN}   6. Verify .env.local file contains all required variables${NC}"
    echo ""
    exit 1
fi 