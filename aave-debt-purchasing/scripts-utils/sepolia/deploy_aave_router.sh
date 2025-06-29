#!/bin/bash

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

forge script script/DeployAaveRouter.s.sol:DeployAaveRouter --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --slow --broadcast
