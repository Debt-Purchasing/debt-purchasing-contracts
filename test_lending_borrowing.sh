#!/bin/bash

echo "🧪 Testing Aave V3 Lending & Borrowing"
echo "======================================"

# Settings
RPC_URL="http://localhost:8545"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEPLOYER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# Token and Pool addresses from comprehensive deployment
WETH_ADDRESS="0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f"
USDC_ADDRESS="0x7bC06c482DEAd17c0e297aFbC32f6e63d3846650"
POOL_ADDRESS="0x2B0d36FACD61B71CC05ab8F3D2355ec3631C0dd5"

echo "🔍 Testing with deployed contracts:"
echo "Pool: $POOL_ADDRESS"
echo "WETH: $WETH_ADDRESS"
echo "USDC: $USDC_ADDRESS"
echo ""

# Function to get balance with proper error handling
get_balance() {
    local token_address=$1
    local user_address=$2
    local result=$(cast call $token_address "balanceOf(address)" $user_address --rpc-url $RPC_URL 2>/dev/null)
    
    if [ "$result" = "0x" ] || [ -z "$result" ]; then
        echo "0"
    else
        # Convert hex to decimal using cast
        cast to-dec $result 2>/dev/null || echo "0"
    fi
}

# Function to convert to human readable amounts
to_human() {
    local amount=$1
    local decimals=$2
    if [ $amount -eq 0 ]; then
        echo "0"
    else
        echo "scale=4; $amount / 10^$decimals" | bc -l 2>/dev/null || echo "Error"
    fi
}

echo "💰 Step 1: Mint some test tokens..."

# Mint 10 WETH to deployer
echo "Minting WETH..."
cast send $WETH_ADDRESS "mint(address,uint256)" $DEPLOYER 10000000000000000000 \
    --private-key $PRIVATE_KEY --rpc-url $RPC_URL > /dev/null 2>&1

# Mint 10000 USDC to deployer  
echo "Minting USDC..."
cast send $USDC_ADDRESS "mint(address,uint256)" $DEPLOYER 10000000000 \
    --private-key $PRIVATE_KEY --rpc-url $RPC_URL > /dev/null 2>&1

echo "✅ Tokens minted"

# Check initial balances
echo "Getting initial balances..."
WETH_BALANCE=$(get_balance $WETH_ADDRESS $DEPLOYER)
USDC_BALANCE=$(get_balance $USDC_ADDRESS $DEPLOYER)

echo "📊 Initial balances (raw):"
echo "WETH: $WETH_BALANCE wei"
echo "USDC: $USDC_BALANCE units"
echo "WETH human: $(to_human $WETH_BALANCE 18)"
echo "USDC human: $(to_human $USDC_BALANCE 6)"
echo ""

# Verify tokens have proper balance before proceeding
if [ "$WETH_BALANCE" = "0" ] || [ "$USDC_BALANCE" = "0" ]; then
    echo "❌ Token balances are 0, checking if contracts exist..."
    
    # Check if contracts have code
    WETH_CODE=$(cast code $WETH_ADDRESS --rpc-url $RPC_URL | head -c 10)
    USDC_CODE=$(cast code $USDC_ADDRESS --rpc-url $RPC_URL | head -c 10)
    
    echo "WETH code: $WETH_CODE"
    echo "USDC code: $USDC_CODE"
    
    if [ "$WETH_CODE" = "0x" ] || [ "$USDC_CODE" = "0x" ]; then
        echo "❌ Contracts don't exist at these addresses"
        exit 1
    fi
    
    echo "❌ Contracts exist but minting failed or balance reading failed"
    exit 1
fi

echo "🏛️ Step 2: Supply 5 WETH to Aave..."

# Approve WETH to Pool
echo "Approving WETH to Pool..."
cast send $WETH_ADDRESS "approve(address,uint256)" $POOL_ADDRESS 5000000000000000000 \
    --private-key $PRIVATE_KEY --rpc-url $RPC_URL > /dev/null 2>&1

# Supply 5 WETH
echo "Supplying WETH to Pool..."
cast send $POOL_ADDRESS "supply(address,uint256,address,uint16)" \
    $WETH_ADDRESS 5000000000000000000 $DEPLOYER 0 \
    --private-key $PRIVATE_KEY --rpc-url $RPC_URL > /dev/null 2>&1

echo "✅ WETH supplied to Aave"

echo "💸 Step 3: Borrow 1000 USDC..."

# Borrow 1000 USDC (variable rate = 2)
echo "Borrowing USDC from Pool..."
cast send $POOL_ADDRESS "borrow(address,uint256,uint256,uint16,address)" \
    $USDC_ADDRESS 1000000000 2 0 $DEPLOYER \
    --private-key $PRIVATE_KEY --rpc-url $RPC_URL > /dev/null 2>&1

echo "✅ USDC borrowed from Aave"

# Check final balances
echo "Getting final balances..."
FINAL_WETH_BALANCE=$(get_balance $WETH_ADDRESS $DEPLOYER)
FINAL_USDC_BALANCE=$(get_balance $USDC_ADDRESS $DEPLOYER)

echo ""
echo "🎯 Final Results:"
echo "================="
echo "WETH Balance: $FINAL_WETH_BALANCE wei ($(to_human $FINAL_WETH_BALANCE 18))"
echo "USDC Balance: $FINAL_USDC_BALANCE units ($(to_human $FINAL_USDC_BALANCE 6))"
echo "Started with:"
echo "WETH: $WETH_BALANCE wei ($(to_human $WETH_BALANCE 18))"
echo "USDC: $USDC_BALANCE units ($(to_human $USDC_BALANCE 6))"
echo ""

# Calculate changes
WETH_CHANGE=$((FINAL_WETH_BALANCE - WETH_BALANCE))
USDC_CHANGE=$((FINAL_USDC_BALANCE - USDC_BALANCE))

echo "📈 Changes:"
echo "WETH: $WETH_CHANGE wei ($(to_human $WETH_CHANGE 18))"
echo "USDC: $USDC_CHANGE units ($(to_human $USDC_CHANGE 6))"

# Success check
if [ $WETH_CHANGE -lt 0 ] && [ $USDC_CHANGE -gt 0 ]; then
    echo ""
    echo "🎉 SUCCESS! Aave V3 lending & borrowing working perfectly!"
    echo "✅ WETH was supplied (balance decreased by $(to_human ${WETH_CHANGE#-} 18))"
    echo "✅ USDC was borrowed (balance increased by $(to_human $USDC_CHANGE 6))"
else
    echo ""
    echo "❌ Unexpected results:"
    echo "Expected: WETH change < 0, USDC change > 0"
    echo "Actual: WETH change = $WETH_CHANGE, USDC change = $USDC_CHANGE"
fi 