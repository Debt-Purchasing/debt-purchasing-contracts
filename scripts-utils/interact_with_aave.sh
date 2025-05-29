#!/bin/bash

# Aave V3 Interaction Utility
echo "🏦 Aave V3 Interaction Utility"
echo "=============================="

# Local settings
LOCAL_RPC_URL="http://localhost:8545"

# Predefined accounts
DEPLOYER_PK="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEPLOYER_ADDR="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

USER1_PK="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
USER1_ADDR="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

USER2_PK="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
USER2_ADDR="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"

USER3_PK="0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
USER3_ADDR="0x90F79bf6EB2c4f870365E785982E1f101E93b906"

USER4_PK="0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"
USER4_ADDR="0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"

# Contract addresses (will be set after deployment)
POOL_PROXY=""
POOL_ADDRESSES_PROVIDER=""
AAVE_ORACLE=""

# Token addresses (will be set after deployment)
WETH_ADDR=""
USDC_ADDR=""
DAI_ADDR=""
WBTC_ADDR=""

function show_accounts() {
    echo ""
    echo "📋 Available Test Accounts:"
    echo "=========================="
    echo "Deployer: $DEPLOYER_ADDR (Admin)"
    echo "User 1:   $USER1_ADDR"
    echo "User 2:   $USER2_ADDR"
    echo "User 3:   $USER3_ADDR"
    echo "User 4:   $USER4_ADDR"
    echo ""
}

function show_main_menu() {
    echo ""
    echo "🏦 Aave V3 Actions:"
    echo "=================="
    echo "1. Show account balances"
    echo "2. Mint test tokens"
    echo "3. Supply/Deposit tokens"
    echo "4. Borrow tokens"
    echo "5. Check Health Factor"
    echo "6. Repay loans"
    echo "7. Withdraw tokens"
    echo "8. Show user account data"
    echo "9. Liquidation scenario setup"
    echo "0. Exit"
    echo ""
}

function select_user() {
    echo ""
    echo "👤 Select User Account:"
    echo "====================="
    echo "1. Deployer ($DEPLOYER_ADDR)"
    echo "2. User 1 ($USER1_ADDR)"
    echo "3. User 2 ($USER2_ADDR)" 
    echo "4. User 3 ($USER3_ADDR)"
    echo "5. User 4 ($USER4_ADDR)"
    echo ""
    read -p "Choose user (1-5): " user_choice
    
    case $user_choice in
        1)
            CURRENT_PK=$DEPLOYER_PK
            CURRENT_ADDR=$DEPLOYER_ADDR
            echo "Selected: Deployer"
            ;;
        2)
            CURRENT_PK=$USER1_PK
            CURRENT_ADDR=$USER1_ADDR
            echo "Selected: User 1"
            ;;
        3)
            CURRENT_PK=$USER2_PK
            CURRENT_ADDR=$USER2_ADDR
            echo "Selected: User 2"
            ;;
        4)
            CURRENT_PK=$USER3_PK
            CURRENT_ADDR=$USER3_ADDR
            echo "Selected: User 3"
            ;;
        5)
            CURRENT_PK=$USER4_PK
            CURRENT_ADDR=$USER4_ADDR
            echo "Selected: User 4"
            ;;
        *)
            echo "❌ Invalid selection"
            return 1
            ;;
    esac
    return 0
}

function mint_test_tokens() {
    select_user
    if [ $? -ne 0 ]; then return; fi
    
    echo ""
    echo "🪙 Minting test tokens for $CURRENT_ADDR..."
    
    # This would need to be implemented with actual contract calls
    echo "Feature coming soon - need to implement ERC20 mint calls"
    echo "For now, all accounts start with 1000 ETH from ganache"
}

function show_balances() {
    select_user
    if [ $? -ne 0 ]; then return; fi
    
    echo ""
    echo "💰 Account Balances for $CURRENT_ADDR:"
    echo "======================================"
    
    # Get ETH balance
    ETH_BALANCE=$(cast balance $CURRENT_ADDR --rpc-url $LOCAL_RPC_URL)
    echo "ETH: $(cast --from-wei $ETH_BALANCE) ETH"
    
    # Get token balances (if contracts are deployed)
    if [ ! -z "$WETH_ADDR" ]; then
        WETH_BALANCE=$(cast call $WETH_ADDR "balanceOf(address)" $CURRENT_ADDR --rpc-url $LOCAL_RPC_URL)
        echo "WETH: $(cast --from-wei $WETH_BALANCE) WETH"
    fi
    
    echo ""
    echo "🏦 Aave Positions:"
    echo "=================="
    echo "Feature coming soon - need to query Aave pool for user data"
}

function check_health_factor() {
    select_user
    if [ $? -ne 0 ]; then return; fi
    
    echo ""
    echo "❤️  Health Factor for $CURRENT_ADDR:"
    echo "===================================="
    
    if [ -z "$POOL_PROXY" ]; then
        echo "❌ Pool address not set. Please update contract addresses first."
        return
    fi
    
    echo "Feature coming soon - need to call getUserAccountData() on Pool"
    echo "This will show:"
    echo "- Total collateral in ETH"
    echo "- Total debt in ETH"
    echo "- Available borrow amount"
    echo "- Current liquidation threshold"
    echo "- Health Factor"
}

function setup_liquidation_scenario() {
    echo ""
    echo "⚠️  Liquidation Scenario Setup"
    echo "=============================="
    echo ""
    echo "This will:"
    echo "1. Have User 1 supply WETH as collateral"
    echo "2. Have User 1 borrow maximum USDC"
    echo "3. Trigger price crash to make position liquidatable"
    echo "4. Have User 2 ready to liquidate"
    echo ""
    read -p "Proceed? (y/n): " confirm
    
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        echo "🚧 Liquidation scenario setup coming soon..."
        echo "Will implement the full flow with actual contract calls"
    fi
}

function update_contract_addresses() {
    echo ""
    echo "📝 Update Contract Addresses"
    echo "==========================="
    echo "Please update these addresses after deployment:"
    echo ""
    read -p "Pool Proxy address: " POOL_PROXY
    read -p "PoolAddressesProvider address: " POOL_ADDRESSES_PROVIDER
    read -p "Aave Oracle address: " AAVE_ORACLE
    echo ""
    read -p "WETH address: " WETH_ADDR
    read -p "USDC address: " USDC_ADDR
    read -p "DAI address: " DAI_ADDR
    read -p "WBTC address: " WBTC_ADDR
    echo ""
    echo "✅ Addresses updated!"
}

# Check if ganache is running
if ! curl -s http://localhost:8545 > /dev/null; then
    echo "❌ Error: Ganache is not running on localhost:8545"
    echo "Please start ganache first with: ./ganache-setup.sh"
    exit 1
fi

echo "✅ Connected to local ganache"
show_accounts

# Main menu loop
while true; do
    show_main_menu
    read -p "Choose action (0-9): " choice
    
    case $choice in
        1)
            show_balances
            ;;
        2)
            mint_test_tokens
            ;;
        3)
            echo "🏦 Supply/Deposit feature coming soon..."
            ;;
        4)
            echo "💸 Borrow feature coming soon..."
            ;;
        5)
            check_health_factor
            ;;
        6)
            echo "💰 Repay feature coming soon..."
            ;;
        7)
            echo "📤 Withdraw feature coming soon..."
            ;;
        8)
            echo "📊 User account data feature coming soon..."
            ;;
        9)
            setup_liquidation_scenario
            ;;
        99)
            update_contract_addresses
            ;;
        0)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please choose 0-9."
            echo "💡 Tip: Use option 99 to update contract addresses after deployment"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done 