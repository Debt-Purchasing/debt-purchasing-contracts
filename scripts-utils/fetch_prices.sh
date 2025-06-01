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
echo -e "${CYAN}📊 FETCHING REAL-TIME TOKEN PRICES FROM COINGECKO${NC}"
echo -e "${BLUE}=======================================================${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRICES_FILE="$SCRIPT_DIR/prices.json"

# Check if prices.json exists
if [ ! -f "$PRICES_FILE" ]; then
    echo -e "${RED}❌ Error: prices.json not found at $PRICES_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Found prices.json at: $PRICES_FILE${NC}"
echo ""

# Token mappings (compatible with older bash)
TOKENS=(
    "WETH:ethereum"
    "wstETH:wrapped-steth"
    "WBTC:wrapped-bitcoin"
    "USDC:usd-coin"
    "DAI:dai"
    "LINK:chainlink"
    "AAVE:aave"
    "cbETH:coinbase-wrapped-staked-eth"
    "USDT:tether"
    "rETH:rocket-pool-eth"
    "LUSD:liquity-usd"
    "CRV:curve-dao-token"
)

echo -e "${YELLOW}🌐 Fetching prices from CoinGecko API...${NC}"
echo ""

# Create a temporary file for the updated JSON
TEMP_FILE=$(mktemp)
cp "$PRICES_FILE" "$TEMP_FILE"

# Function to convert price to 8 decimals (multiplied by 10^8)
convert_to_8_decimals() {
    local price=$1
    # Use awk instead of bc for better compatibility
    echo "$price" | awk '{printf "%.0f", $1 * 100000000}'
}

# Function to update token price in JSON
update_token_price() {
    local token=$1
    local new_price=$2
    local temp_file=$3
    
    # Use jq to update the price field for the specific token
    jq --arg token "$token" --arg price "$new_price" '
        map(if .token == $token then .price = $price else . end)
    ' "$temp_file" > "${temp_file}.tmp" && mv "${temp_file}.tmp" "$temp_file"
}

# Function to get coingecko ID for token
get_coingecko_id() {
    local token=$1
    for mapping in "${TOKENS[@]}"; do
        if [[ "$mapping" == "$token:"* ]]; then
            echo "${mapping#*:}"
            return
        fi
    done
}

# Build token IDs for bulk API request
TOKEN_IDS=""
for mapping in "${TOKENS[@]}"; do
    coingecko_id="${mapping#*:}"
    if [ -n "$TOKEN_IDS" ]; then
        TOKEN_IDS="${TOKEN_IDS},"
    fi
    TOKEN_IDS="${TOKEN_IDS}${coingecko_id}"
done

echo -e "${CYAN}🔍 Fetching prices for tokens: ${TOKEN_IDS}${NC}"
echo ""

# Make bulk API request to CoinGecko
API_URL="https://api.coingecko.com/api/v3/simple/price?ids=${TOKEN_IDS}&vs_currencies=usd&precision=18"

echo -e "${YELLOW}📡 API Request: ${API_URL}${NC}"
echo ""

# Fetch prices with error handling
if PRICE_DATA=$(curl -s "$API_URL"); then
    echo -e "${GREEN}✅ Successfully fetched price data from CoinGecko${NC}"
    echo ""
    
    # Check if we got valid JSON response
    if ! echo "$PRICE_DATA" | jq . >/dev/null 2>&1; then
        echo -e "${RED}❌ Invalid JSON response from CoinGecko API${NC}"
        echo -e "${YELLOW}Response: $PRICE_DATA${NC}"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    
    # Process each token
    for mapping in "${TOKENS[@]}"; do
        token="${mapping%:*}"
        coingecko_id="${mapping#*:}"
        
        # Extract price from JSON response
        price_usd=$(echo "$PRICE_DATA" | jq -r ".\"$coingecko_id\".usd // empty")
        
        if [ -n "$price_usd" ] && [ "$price_usd" != "null" ] && [ "$price_usd" != "empty" ]; then
            # Convert to 8 decimals
            price_8_decimals=$(convert_to_8_decimals "$price_usd")
            
            echo -e "${CYAN}💰 $token: \$${price_usd} USD = ${price_8_decimals} (8 decimals)${NC}"
            
            # Update the price in JSON
            update_token_price "$token" "$price_8_decimals" "$TEMP_FILE"
        else
            echo -e "${RED}❌ Failed to fetch price for $token (${coingecko_id})${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}💾 Updating prices.json...${NC}"
    
    # Replace original file with updated version
    mv "$TEMP_FILE" "$PRICES_FILE"
    
    echo -e "${GREEN}✅ Successfully updated all token prices!${NC}"
    echo ""
    
    echo -e "${PURPLE}📋 UPDATED PRICES SUMMARY:${NC}"
    echo -e "${CYAN}===========================================${NC}"
    
    # Display updated prices in a nice format
    jq -r '.[] | "💰 \(.token): \(.price) (8 decimals)"' "$PRICES_FILE"
    
    echo ""
    echo -e "${GREEN}🎉 Price update completed successfully!${NC}"
    echo -e "${CYAN}📄 Updated file: $PRICES_FILE${NC}"
    
else
    echo -e "${RED}❌ Failed to fetch prices from CoinGecko API${NC}"
    echo -e "${YELLOW}💡 Please check your internet connection and try again${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo ""
echo -e "${BLUE}=======================================================${NC}"
echo -e "${GREEN}✨ PRICE FETCHING OPERATION COMPLETE ✨${NC}"
echo -e "${BLUE}=======================================================${NC}"
