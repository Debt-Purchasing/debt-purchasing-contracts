#!/bin/bash

# Load environment variables
set -a
source .env
set +a

# Chain ID from command line argument
CHAIN_ID=$1
if [[ -z "$CHAIN_ID" ]]; then
    echo "Usage: $0 <chain-id>"
    exit 1
fi

# Determine network and paths
BROADCAST_DIR="broadcast/DeployAaveRouter.s.sol/$CHAIN_ID"
LATEST_RUN_FILE=$(ls -t "$BROADCAST_DIR"/*.json | head -n 1)

if [[ -z "$LATEST_RUN_FILE" ]]; then
    echo "No deployment file found in $BROADCAST_DIR"
    exit 1
fi

echo "Using deployment file: $LATEST_RUN_FILE"

# Extract contract address and constructor arguments
AAVE_ROUTER_ADDRESS=$(jq -r '.transactions[] | select(.transactionType == "CREATE" and .contractName == "AaveRouter") | .contractAddress' "$LATEST_RUN_FILE")
CONSTRUCTOR_ARGS=$(jq -r '.transactions[] | select(.transactionType == "CREATE" and .contractName == "AaveRouter") | .arguments | @json' "$LATEST_RUN_FILE" | tr -d '[]" ')

if [[ -z "$AAVE_ROUTER_ADDRESS" || -z "$CONSTRUCTOR_ARGS" ]]; then
    echo "Could not find required data in deployment file:"
    echo "AaveRouter address: $AAVE_ROUTER_ADDRESS"
    echo "Constructor args: $CONSTRUCTOR_ARGS"
    exit 1
fi

# Format constructor arguments properly
# Remove brackets and quotes, then replace commas with spaces
FORMATTED_ARGS=$(echo "$CONSTRUCTOR_ARGS" | sed 's/,/ /g')

echo "AaveRouter address: $AAVE_ROUTER_ADDRESS"
echo "Constructor args: $FORMATTED_ARGS"

# Verify contract
echo "Verifying AaveRouter contract..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    --verifier etherscan \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,address)" $FORMATTED_ARGS) \
    "$AAVE_ROUTER_ADDRESS" \
    src/AaveRouter.sol:AaveRouter

echo "Verification process completed!"