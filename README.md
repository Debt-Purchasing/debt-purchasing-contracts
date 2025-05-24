# Debt Purchasing Contracts

A sophisticated DeFi protocol enabling the purchase and transfer of debt positions on Aave V3. This system allows users to create leveraged positions, tokenize their debt, and enable a marketplace for debt trading with automated risk management.

## 🎯 Overview

The Debt Purchasing Protocol revolutionizes DeFi by creating a marketplace for debt positions. Users can:

- **Create Isolated Debt Positions**: Deploy individual debt contracts as isolated wallets
- **Leverage Trading**: Deposit collateral and borrow assets on Aave V3 with enhanced control
- **Debt Marketplace**: Create and execute debt sale orders (full or partial)
- **Risk Management**: Automated Health Factor monitoring and liquidation protection
- **Ownership Transfer**: Seamless transfer of debt positions between users

## 🏗️ System Architecture

### Core Components

#### 1. AaveRouter.sol - Central Hub

The main orchestrator that manages all interactions with Aave V3 and debt operations.

**Key Features:**

- **Debt Creation**: Deploy isolated debt positions using minimal proxy pattern
- **Aave Integration**: Direct interaction with Aave V3 Pool for lending operations
- **Order Management**: Handle both full and partial debt sale orders
- **Ownership Tracking**: Maintain debt ownership and nonce management
- **Multicall Support**: Batch multiple operations in a single transaction

#### 2. AaveDebt.sol - Isolated Debt Position

Individual debt contracts that act as isolated wallets for each position.

**Key Features:**

- **Isolated Positions**: Each debt is an independent contract
- **Aave Operations**: Direct borrowing, repaying, and withdrawing capabilities
- **Router Control**: Only the router can execute operations
- **aToken Support**: Native support for repaying with aTokens

#### 3. Debt Ownership Registry

Tracks ownership and provides security through nonce-based order invalidation.

## 🔗 Aave V3 Integration

### Architecture Overview

```
User → AaveRouter → AaveDebt → Aave V3 Pool
  ↓                    ↓
Order Management    Isolated Position
  ↓                    ↓
Debt Trading      Collateral & Debt
```

### Core Aave Operations

#### 1. Supply Collateral

```solidity
function callSupply(address debt, address asset, uint256 amount)
function callSupplyWithPermit(address debt, address asset, uint256 amount, ...)
```

**Process:**

1. Transfer tokens from user to router
2. Approve Aave pool for token spending
3. Supply tokens to Aave on behalf of the debt contract
4. Debt contract receives aTokens as collateral

#### 2. Borrow Assets

```solidity
function callBorrow(address debt, address asset, uint256 amount, uint256 interestRateMode, address receiver)
```

**Process:**

1. Verify caller owns the debt position
2. Call borrow on the debt contract
3. Debt contract borrows from Aave
4. Borrowed tokens transferred to specified receiver

**Interest Rate Modes:**

- `1`: Stable rate borrowing
- `2`: Variable rate borrowing

#### 3. Repay Debt

```solidity
function callRepay(address debt, address asset, uint256 amount, uint256 interestRateMode)
function callRepayWithPermit(address debt, address asset, uint256 amount, ...)
function callRepayWithATokens(address debt, address asset, uint256 amount, uint256 interestRateMode)
```

**Process:**

1. Transfer repay tokens to router
2. Approve Aave pool for spending
3. Repay debt on behalf of debt contract
4. Return any excess tokens to user

**Special Features:**

- **USDT Compatibility**: Two-step approval process
- **aToken Repayment**: Direct repayment using aTokens
- **Partial Repayment**: Automatic handling of partial repays

#### 4. Withdraw Collateral

```solidity
function callWithdraw(address debt, address asset, uint256 amount, address to)
```

**Process:**

1. Verify caller owns the debt position
2. Withdraw aTokens from Aave
3. Transfer underlying tokens to specified address

### Health Factor Management

The system continuously monitors Aave's Health Factor (HF) for risk management:

```solidity
(uint256 totalCollateralBase, uint256 totalDebtBase, , , , uint256 hf) = aavePool.getUserAccountData(debt);
```

**Health Factor Rules:**

- `HF > 1`: Position is healthy
- `HF = 1`: Position at liquidation threshold
- `HF < 1`: Position can be liquidated

## 💰 Debt Trading Mechanisms

### 1. Full Sale Orders

Complete transfer of debt position ownership.

```solidity
struct FullSellOrder {
    OrderTitle title;           // Order metadata
    address fullSaleToken;      // Payment token
    uint256 fullSaleExtra;      // Premium percentage (basis points)
    uint8 v; bytes32 r; bytes32 s;  // Signature
}
```

**Execution Process:**

1. Verify order signature and validity
2. Check Health Factor against trigger threshold
3. Calculate payment amount: `totalDebt + premium`
4. Transfer payment from buyer to seller
5. Transfer debt ownership to buyer
6. Invalidate all existing orders via nonce increment

**Example:**

- Total Debt: $10,000
- Premium: 5% (500 basis points)
- Buyer pays: $10,500
- Buyer receives: Full debt position + all collateral

### 2. Partial Sale Orders

Partial debt reduction in exchange for proportional collateral.

```solidity
struct PartialSellOrder {
    OrderTitle title;
    uint256 interestRateMode;   // Debt type to repay
    uint256 minHF;              // Minimum final Health Factor
    address[] collateralOut;    // Collateral tokens to withdraw
    uint256[] percents;         // Withdrawal percentages
    address repayToken;         // Token for debt repayment
    uint256 repayAmount;        // Amount to repay
    uint256 bonus;              // Bonus percentage for buyer
    uint8 v; bytes32 r; bytes32 s;
}
```

**Execution Process:**

1. Verify order signature and Health Factor
2. Buyer provides `repayAmount` of `repayToken`
3. Repay specified debt on Aave
4. Calculate collateral withdrawal amounts
5. Add bonus percentage to withdrawal amounts
6. Withdraw collateral to buyer
7. Verify final Health Factor meets minimum requirement

**Example:**

- Buyer repays: $5,000 USDC debt
- Collateral value: $5,250 (5% bonus included)
- Seller benefits: Improved Health Factor, reduced debt
- Buyer benefits: $250 profit from bonus

### Order Security

#### Signature Verification

All orders use EIP-712 structured data signing:

```solidity
bytes32 public constant FULL_SELL_ORDER_TYPE_HASH = keccak256("FullSellOrder(...)");
bytes32 public constant PARTIAL_SELL_ORDER_TYPE_HASH = keccak256("PartialSellOrder(...)");
```

#### Nonce Management

- **User Nonces**: Increment when creating new debt positions
- **Debt Nonces**: Increment when transferring ownership or canceling orders
- **Automatic Invalidation**: Old orders become invalid when nonces change

#### Time-based Validity

```solidity
struct OrderTitle {
    address debt;
    uint256 debtNonce;
    uint256 startTime;    // Order activation time
    uint256 endTime;      // Order expiration time
    uint256 triggerHF;    // Health Factor threshold
}
```

## 🛡️ Risk Management

### Health Factor Monitoring

- **Continuous Tracking**: Real-time HF calculation from Aave
- **Trigger Thresholds**: Orders only execute when HF drops below specified levels
- **Liquidation Protection**: Automated execution prevents forced liquidations

### Price Oracle Integration

Direct integration with Aave's price oracles for accurate valuations:

```solidity
IPriceOracleGetter public aaveOracle;
uint256 tokenPrice = aaveOracle.getAssetPrice(token);  // 8 decimals
```

### Precision Handling

Robust decimal conversion between different token precisions:

```solidity
function _getTokenValueFromBaseValue(uint256 baseValue, address token, uint256 tokenPrice)
function _getBaseValueFromTokenValue(address token, uint256 tokenValue, uint256 tokenPrice)
```

## 🚀 Usage Examples

### Creating a Leveraged Position

```solidity
// 1. Create isolated debt position
address debt = aaveRouter.createDebt();

// 2. Supply collateral (ETH)
aaveRouter.callSupply(debt, WETH, 10e18);

// 3. Borrow against collateral (USDC)
aaveRouter.callBorrow(debt, USDC, 15000e6, 2, msg.sender);

// 4. Use borrowed USDC for additional investments
```

### Creating a Full Sale Order

```solidity
// 1. Create order structure
IAaveRouter.FullSellOrder memory order = IAaveRouter.FullSellOrder({
    title: IAaveRouter.OrderTitle({
        debt: myDebtAddress,
        debtNonce: currentNonce,
        startTime: block.timestamp,
        endTime: block.timestamp + 7 days,
        triggerHF: 1.1e18  // Trigger when HF drops below 1.1
    }),
    fullSaleToken: USDC,
    fullSaleExtra: 500,  // 5% premium
    v: v, r: r, s: s     // Signature components
});

// 2. Sign order off-chain
// 3. Buyer executes when conditions are met
aaveRouter.executeFullSaleOrder(order, minProfitRequired);
```

### Executing a Partial Purchase

```solidity
// 1. Buyer finds attractive partial order
// 2. Execute partial purchase
aaveRouter.excutePartialSellOrder(partialOrder);

// 3. Automatically:
//    - Repays portion of seller's debt
//    - Withdraws proportional collateral + bonus
//    - Improves seller's Health Factor
```

## 🔧 Technical Specifications

### Dependencies

- **OpenZeppelin**: Proxy patterns, security utilities
- **Aave V3**: Core lending protocol integration
- **EIP-712**: Structured data signing

### Supported Networks

- **Sepolia Testnet**: `0xD64dDe119f11C88850FD596BE11CE398CC5893e6`
- **Mainnet**: (Coming soon)

### Gas Optimization

- **Minimal Proxy Pattern**: Efficient debt contract deployment
- **Multicall Support**: Batch operations to reduce gas costs
- **Optimized Storage**: Efficient state management

## 🛠️ Development Setup

### Prerequisites

- **Foundry**: Latest version with Forge, Cast, and Anvil
- **Node.js**: v16+ for additional tooling
- **Git**: Version control

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/debt-purchasing-contracts.git
cd debt-purchasing-contracts

# Install dependencies
forge install

# Compile contracts
forge build

# Run tests
forge test

# Run with gas reporting
forge test --gas-report

# Deploy to testnet
forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### Testing

The test suite covers:

- ✅ Debt creation and ownership
- ✅ Aave integration (supply, borrow, repay, withdraw)
- ✅ Full and partial sale order execution
- ✅ Health Factor management
- ✅ Edge cases and error conditions
- ✅ Gas optimization verification

```bash
# Run specific test file
forge test --match-path test/AaveRouter.t.sol

# Run with detailed output
forge test -vvv

# Generate coverage report
forge coverage
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

_Built with ❤️ for the DeFi community_
