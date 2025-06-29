#!/bin/bash

echo "🚀 Starting Anvil"

# Kill any existing anvil process
pkill -f anvil > /dev/null 2>&1 || true

echo "🚀 Starting anvil..."


# Navigate to project root first (detect where we are)
# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Navigate to project root
cd "$PROJECT_ROOT"

# Load existing environment variables from .env.local if it exists
if [ -f ".env.local" ]; then
    source .env.local
else
    echo "⚠️  No existing .env.local found, will create new one"
fi

# Start anvil with new syntax
anvil --accounts 101 \
    --gas-price 20000000000 \
    --gas-limit 150000000 \
    --chain-id ${CHAIN_ID} \
    --host ${LOCAL_RPC_URL} \
    --port ${PORT}

echo ""
echo "✅ Anvil should be running!"
echo "📋 Configuration:"
echo "🌐 RPC URL: ${LOCAL_RPC_URL}:${PORT}"
echo "⛓️  Chain ID: ${CHAIN_ID}"
echo "👥 Accounts: 101 total"
echo "💰 Balance: 10000 ETH each"
echo ""
echo "🔧 Account #0 (Deployer/Whale):"
echo "   Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo "   Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
echo ""
echo "🏦 Accounts 1-100: Available for user operations"
