# Debt Purchasing Contracts

Smart contracts for the debt purchasing platform, enabling the purchase and transfer of debt positions on Aave V3.

## Overview

The contracts in this repository allow users to:

- Deposit collateral and borrow assets on Aave
- Create debt sale offers with specific conditions
- Purchase debt positions from other users
- Track ownership of debt positions

## Contract Architecture

- `DebtVault.sol`: Manages interactions with Aave for deposits, borrows, repayments, and withdrawals
- `DebtSaleManager.sol`: Handles debt sale offers and executions
- `DebtOwnershipRegistry.sol`: Tracks ownership of debt positions

## Setup

### Prerequisites

- Foundry (Forge, Cast, Anvil)
- Aave V3 testnet deployment

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/debt-purchasing-contracts.git
cd debt-purchasing-contracts

# Install dependencies
forge install

# Compile contracts
forge build
```

### Testing

```bash
# Run tests
forge test

# Run tests with gas reporting
forge test --gas-report
```

### Deployment

```bash
# Deploy to a testnet (e.g., Sepolia)
forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

## Integration with Aave V3

This platform integrates with Aave V3 to manage debt positions. The key integration points are:

- DebtVault.sol: Interacts with the Aave Pool for deposits, borrows, repayments, and withdrawals
- Testnet addresses:
  - Sepolia: 0xD64dDe119f11C88850FD596BE11CE398CC5893e6 (PoolAddressesProvider)

## License

This project is licensed under the MIT License.
