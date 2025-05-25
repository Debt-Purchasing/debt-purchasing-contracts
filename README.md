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

Complete transfer of debt position ownership with **corrected equity-based pricing**.

```solidity
struct FullSellOrder {
    OrderTitle title;           // Order metadata
    address token;              // Payment token
    uint256 percentOfEquity;    // Percentage of net equity going to seller
    uint8 v; bytes32 r; bytes32 s;  // Signature
}
```

**Corrected Business Logic:**

- **Net Equity Calculation**: `netEquity = totalCollateral - totalDebt`
- **Premium Calculation**: `premium = netEquity × percentOfEquity / 10000`
- **Seller Receives**: Only the premium (not total payment)
- **Buyer Pays**: Premium to seller + assumes debt responsibility

**Execution Process:**

1. Verify order signature and validity
2. Check Health Factor against trigger threshold
3. Calculate net equity: `totalCollateral - totalDebt`
4. Calculate premium: `netEquity × percentOfEquity`
5. Transfer premium from buyer to seller
6. Transfer debt ownership to buyer
7. Invalidate all existing orders via nonce increment

**Realistic Example:**

- **Alice's Position**: $50K collateral, $25.5K debt → Net equity = $24.5K
- **Crisis**: Market drops, HF falls to 1.063 (dangerous)
- **Order**: 90% of equity to seller
- **Bob Pays**: $22,050 premium (90% × $24.5K)
- **Bob Gets**: Full ownership + $2,450 profit (10% of equity)
- **Alice Gets**: $22,050 (preserves 90% of her equity, avoids liquidation)

### 2. Partial Sale Orders

Partial debt reduction in exchange for proportional collateral with **simplified validation**.

```solidity
struct PartialSellOrder {
    OrderTitle title;
    uint256 interestRateMode;   // Debt type to repay
    address[] collateralOut;    // Collateral tokens to withdraw
    uint256[] percents;         // Withdrawal percentages
    address repayToken;         // Token for debt repayment
    uint256 repayAmount;        // Amount to repay
    uint256 bonus;              // Bonus percentage for buyer
    uint8 v; bytes32 r; bytes32 s;
}
```

**Simplified Logic (MinHF Removed):**

- **Validation**: `finalHF > initialHF` (ensures seller always benefits)
- **No Complex Calculations**: Simple improvement check
- **Win-Win Guarantee**: Seller's position always improves

**Execution Process:**

1. Verify order signature and Health Factor
2. Buyer provides `repayAmount` of `repayToken`
3. Repay specified debt on Aave
4. Calculate collateral withdrawal amounts
5. Add bonus percentage to withdrawal amounts
6. Withdraw collateral to buyer
7. Verify final HF > initial HF

**Example:**

- **Alice's Crisis**: HF drops to 1.353 (risky)
- **Bob's Help**: Pays $3,000 USDC to repay debt
- **Bob Gets**: Proportional WETH + 1% bonus
- **Result**: Alice's HF improves to 1.422 (safer), Bob profits from bonus

### Order Security

#### Signature Verification

All orders use EIP-712 structured data signing:

```solidity
bytes32 public constant FULL_SELL_ORDER_TYPE_HASH =
    keccak256("FullSellOrder(uint256 chainId,address contract,OrderTitle title,address token,uint256 percentOfEquity)");
bytes32 public constant PARTIAL_SELL_ORDER_TYPE_HASH =
    keccak256("PartialSellOrder(...)");
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

### Creating a Full Sale Order (Updated)

```solidity
// 1. Create order structure with corrected parameters
IAaveRouter.FullSellOrder memory order = IAaveRouter.FullSellOrder({
    title: IAaveRouter.OrderTitle({
        debt: myDebtAddress,
        debtNonce: currentNonce,
        startTime: block.timestamp,
        endTime: block.timestamp + 7 days,
        triggerHF: 1.1e18  // Trigger when HF drops below 1.1
    }),
    token: WBTC,              // Payment token (renamed from fullSaleToken)
    percentOfEquity: 9000,    // 90% of net equity to seller (renamed from fullSaleExtra)
    v: v, r: r, s: s         // Signature components
});

// 2. Sign order off-chain using updated type hash
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
//    - Improves seller's Health Factor (finalHF > initialHF)
```

## 🔧 Technical Specifications

### Recent Improvements

#### 1. Corrected Full Sale Economics

- **Fixed Premium Logic**: Premium now based on net equity, not debt
- **Realistic Percentages**: 90% equity to seller, 10% profit to buyer
- **Proper Payment Flow**: Seller gets premium, buyer assumes debt

#### 2. Simplified Partial Sales

- **Removed MinHF Complexity**: Simple `finalHF > initialHF` validation
- **Reduced Gas Costs**: Eliminated complex calculations
- **Guaranteed Win-Win**: Seller always benefits from partial sales

#### 3. Improved Code Clarity

- **Better Naming**: `fullSaleToken` → `token`, `fullSaleExtra` → `percentOfEquity`
- **Self-Documenting**: Parameter names clearly describe their purpose
- **Maintainable**: Easier to understand and modify

#### 4. Enhanced Testing

- **Simplified Price Manipulation**: Uniform price drops for predictable results
- **Realistic Scenarios**: Tests reflect real-world usage patterns
- **Comprehensive Coverage**: Both full and partial sale scenarios

### Dependencies

- **OpenZeppelin**: Proxy patterns, security utilities
- **Aave V3**: Core lending protocol integration
- **EIP-712**: Structured data signing

### Supported Networks

- **Sepolia Testnet**: Deployed and tested
- **Mainnet**: Ready for deployment

### Gas Optimization

- **Minimal Proxy Pattern**: Efficient debt contract deployment (~2k gas vs full deployment)
- **Multicall Support**: Batch operations to reduce gas costs
- **Optimized Storage**: Efficient state management with packed structs

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
- ✅ Full and partial sale order execution with corrected logic
- ✅ Health Factor management and improvement validation
- ✅ Realistic market scenarios with proper price manipulation
- ✅ Edge cases and error conditions
- ✅ Gas optimization verification

```bash
# Run specific test file
forge test --match-path test/fork-mainnet/aave/AaveDebtPurchasingInteractTest.t.sol

# Run with detailed output
forge test -vvv

# Test specific scenarios
forge test --match-test "testPartialSaleOrder|testFullSaleWithMulticall"

# Generate coverage report
forge coverage
```

### Key Test Scenarios

#### Full Sale Test

- **Setup**: Alice with $50K collateral, $25.5K debt (HF = 1.549)
- **Crisis**: 45% market drop → HF = 1.063 (below 1.1 trigger)
- **Execution**: Bob pays 90% of equity ($22,050), gets ownership + 10% profit
- **Result**: Alice preserves most equity, Bob gets profitable position

#### Partial Sale Test

- **Setup**: Same Alice position in crisis (HF = 1.353)
- **Help**: Bob pays $3,000 USDC to reduce debt
- **Benefit**: Alice's HF improves to 1.422, Bob gets WETH + 1% bonus
- **Validation**: `finalHF > initialHF` ensures Alice always benefits

## 📈 Economic Model

### Full Sale Economics

**For a $50K collateral, $25.5K debt position:**

| Scenario   | Alice Receives | Bob Pays      | Bob's Profit | Alice's Outcome      |
| ---------- | -------------- | ------------- | ------------ | -------------------- |
| 90% Equity | $22,050        | $47,550 total | $2,450 (10%) | Preserves 90% equity |
| 80% Equity | $19,600        | $45,100 total | $4,900 (20%) | Preserves 80% equity |
| 70% Equity | $17,150        | $42,650 total | $7,350 (30%) | Preserves 70% equity |

### Partial Sale Economics

**Benefits for both parties:**

- **Seller**: Improved Health Factor, reduced liquidation risk
- **Buyer**: Immediate profit from bonus percentage
- **System**: Prevents liquidations, maintains market stability

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

_Built with ❤️ for the DeFi community_
