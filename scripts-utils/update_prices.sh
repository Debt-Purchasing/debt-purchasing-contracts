#!/bin/bash

# Oracle Price Update Utility Scripts
echo "🔧 Oracle Price Update Utility"
echo "=============================="

# Local settings
LOCAL_RPC_URL="http://localhost:8545"
LOCAL_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

function show_menu() {
    echo ""
    echo "📊 Available Price Update Scenarios:"
    echo "1. Reset to baseline mainnet prices"
    echo "2. Crash scenario (-50% for all assets)" 
    echo "3. Bull market (+30% for all assets)"
    echo "4. Stablecoin depeg (USDC/DAI/USDT to $0.85)"
    echo "5. ETH pump (+20% ETH ecosystem)"
    echo "6. Check current prices"
    echo "0. Exit"
    echo ""
}

function reset_baseline() {
    echo "🔄 Resetting all prices to mainnet baseline..."
    
    forge script script/utilities/UpdateOraclePrices.sol:UpdateOraclePrices \
        --sig "resetToBaseline()" \
        --rpc-url $LOCAL_RPC_URL \
        --private-key $LOCAL_PRIVATE_KEY \
        --broadcast \
        -v
}

function crash_scenario() {
    echo "📉 Applying crash scenario (-50% for all assets)..."
    
    forge script script/utilities/UpdateOraclePrices.sol:UpdateOraclePrices \
        --sig "crashScenario()" \
        --rpc-url $LOCAL_RPC_URL \
        --private-key $LOCAL_PRIVATE_KEY \
        --broadcast \
        -v
}

function bull_market() {
    echo "📈 Applying bull market (+30% for all assets)..."
    
    forge script script/utilities/UpdateOraclePrices.sol:UpdateOraclePrices \
        --sig "bullMarket()" \
        --rpc-url $LOCAL_RPC_URL \
        --private-key $LOCAL_PRIVATE_KEY \
        --broadcast \
        -v
}

function stablecoin_depeg() {
    echo "⚠️  Applying stablecoin depeg (USDC/DAI/USDT to $0.85)..."
    
    forge script script/utilities/UpdateOraclePrices.sol:UpdateOraclePrices \
        --sig "stablecoinDepeg()" \
        --rpc-url $LOCAL_RPC_URL \
        --private-key $LOCAL_PRIVATE_KEY \
        --broadcast \
        -v
}

function eth_pump() {
    echo "⚡ Applying ETH pump (+20% ETH ecosystem)..."
    
    forge script script/utilities/UpdateOraclePrices.sol:UpdateOraclePrices \
        --sig "ethPump()" \
        --rpc-url $LOCAL_RPC_URL \
        --private-key $LOCAL_PRIVATE_KEY \
        --broadcast \
        -v
}

function check_prices() {
    echo "📊 Current Oracle Prices:"
    echo "========================"
    
    # Note: You'll need to implement a getter function for this
    # For now, just show baseline prices
    echo "WETH: $2,563 (baseline)"
    echo "wstETH: $2,956 (baseline)"
    echo "WBTC: $42,826 (baseline)"
    echo "USDC: $1.00 (baseline)"
    echo "DAI: $0.99 (baseline)"
    echo "LINK: $14.21 (baseline)"
    echo "AAVE: $106.47 (baseline)"
    echo "cbETH: $2,711 (baseline)"
    echo "USDT: $0.99 (baseline)"
    echo "rETH: $2,807 (baseline)"
    echo "LUSD: $1.008 (baseline)"
    echo "CRV: $0.55 (baseline)"
}

# Main menu loop
while true; do
    show_menu
    read -p "Choose option (0-6): " choice
    
    case $choice in
        1)
            reset_baseline
            ;;
        2)
            crash_scenario
            ;;
        3)
            bull_market
            ;;
        4)
            stablecoin_depeg
            ;;
        5)
            eth_pump
            ;;
        6)
            check_prices
            ;;
        0)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please choose 0-6."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done 