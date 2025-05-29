#!/bin/bash

echo "🚀 Starting Ganache-CLI with Deterministic Accounts"
echo "===================================================="

# Kill any existing ganache process
pkill -f ganache

# # Check if ganache is installed globally
# if ! command -v ganache &> /dev/null; then
#     echo "📦 Installing latest ganache globally..."
#     npm install -g ganache@latest
# fi

echo "🔧 Starting Ganache-CLI on localhost:8545"
echo "💰 Pre-funded accounts with 1000 ETH each"
echo "🔑 Using deterministic mnemonic for consistent accounts"
echo ""

# Start ganache-cli with deterministic mnemonic for consistent accounts
ganache-cli \
    --mnemonic "test test test test test test test test test test test junk" \
    --accounts 10 \
    --host 127.0.0.1 \
    --port 8545 \
    --gasLimit 30000000 \
    --gasPrice 20000000000 \
    --blockTime 2

echo ""
echo "✅ Ganache-CLI should be running!"
echo "📋 Check the output above for account addresses and private keys"
echo "🌐 RPC URL: http://localhost:8545"
echo "⛓️  Network ID: 1337 (default)"
echo ""
echo "🔧 For deployment, use the first account (Account #0) as deployer"
echo "📝 With deterministic mnemonic, Account #0 should be:"
echo "   Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo "   Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" 