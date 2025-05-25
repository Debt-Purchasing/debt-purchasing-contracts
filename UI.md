# Debt Purchasing Protocol - UI/UX Documentation

This document provides comprehensive guidance for building user interfaces for the Debt Purchasing Protocol, including parameter explanations, user workflows, and interaction patterns.

## 🎯 Overview

The Debt Purchasing Protocol enables two main user interactions:

1. **Debt Position Management**: Create, manage, and monitor leveraged positions
2. **Debt Trading**: Buy and sell debt positions through signed orders

## 🔧 Function Call Mapping for UI Developers

This section maps each UI use case to the specific smart contract function calls needed for implementation.

### 📋 Position Management Functions

#### 1. Create New Debt Position

**UI Use Case**: User wants to create a new leveraged position

```javascript
// Step 1: Predict the debt address (for UI display)
const predictedAddress = await router.predictDebtAddress(userAddress);

// Step 2: Create position with initial supply/borrow (using multicall)
const multicallData = [
  // Create the debt contract
  router.interface.encodeFunctionData("createDebt", []),

  // Supply collateral (e.g., WETH)
  router.interface.encodeFunctionData("callSupply", [
    predictedAddress,
    WETH_ADDRESS,
    ethers.parseEther("5"), // 5 WETH
  ]),

  // Borrow against collateral (e.g., USDC)
  router.interface.encodeFunctionData("callBorrow", [
    predictedAddress,
    USDC_ADDRESS,
    ethers.parseUnits("10000", 6), // 10,000 USDC
    2, // Variable interest rate
    userAddress, // Receiver
  ]),
];

// Execute all operations in one transaction
await router.multicall(multicallData);
```

#### 2. Add Collateral to Existing Position

**UI Use Case**: User wants to improve their Health Factor by adding collateral

```javascript
await router.callSupply(
  debtAddress,
  WETH_ADDRESS,
  ethers.parseEther("2") // Add 2 more WETH
);
```

#### 3. Repay Debt

**UI Use Case**: User wants to reduce debt to improve Health Factor

```javascript
await router.callRepay(
  debtAddress,
  USDC_ADDRESS,
  ethers.parseUnits("5000", 6), // Repay 5,000 USDC
  2 // Variable interest rate
);
```

#### 4. Withdraw Collateral

**UI Use Case**: User wants to withdraw excess collateral

```javascript
await router.callWithdraw(
  debtAddress,
  WETH_ADDRESS,
  ethers.parseEther("1"), // Withdraw 1 WETH
  userAddress // Recipient
);
```

### 📝 Order Creation Functions

#### 5. Create Full Sale Order

**UI Use Case**: User wants to sell their entire position when HF drops

```javascript
// Step 1: Prepare order data
const orderTitle = {
  debt: debtAddress,
  debtNonce: await router.debtNonces(debtAddress),
  startTime: Math.floor(Date.now() / 1000), // Now
  endTime: Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60, // 7 days
  triggerHF: ethers.parseEther("1.1"), // Trigger at HF 1.1
};

const fullSaleOrder = {
  title: orderTitle,
  token: WBTC_ADDRESS, // Payment token
  percentOfEquity: 9000, // 90% of equity to seller
  v: 0,
  r: ethers.ZeroHash,
  s: ethers.ZeroHash, // Will be filled by signature
};

// Step 2: Create signature hash (matches contract verification)
// First, create the title hash
const titleHash = ethers.keccak256(
  ethers.AbiCoder.defaultAbiCoder().encode(
    ["bytes32", "address", "uint256", "uint256", "uint256", "uint256"],
    [
      await router.ORDER_TITLE_TYPE_HASH(),
      orderTitle.debt,
      orderTitle.debtNonce,
      orderTitle.startTime,
      orderTitle.endTime,
      orderTitle.triggerHF,
    ]
  )
);

// Then create the full order struct hash
const structHash = ethers.keccak256(
  ethers.AbiCoder.defaultAbiCoder().encode(
    ["bytes32", "uint256", "address", "bytes32", "address", "uint256"],
    [
      await router.FULL_SELL_ORDER_TYPE_HASH(),
      await provider.getNetwork().then((n) => n.chainId), // chainId
      await router.getAddress(), // contract address
      titleHash,
      fullSaleOrder.token,
      fullSaleOrder.percentOfEquity,
    ]
  )
);

// Sign the struct hash directly (no EIP-712 domain)
const signature = await signer.signMessage(ethers.getBytes(structHash));
const { v, r, s } = ethers.Signature.from(signature);

// Update order with signature
fullSaleOrder.v = v;
fullSaleOrder.r = r;
fullSaleOrder.s = s;

// Order is now ready to be stored off-chain or shared
```

#### 6. Create Partial Sale Order

**UI Use Case**: User wants to get help with debt repayment

```javascript
// Step 1: Prepare order data
const orderTitle = {
  debt: debtAddress,
  debtNonce: await router.debtNonces(debtAddress),
  startTime: Math.floor(Date.now() / 1000),
  endTime: Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60,
  triggerHF: ethers.parseEther("1.2"), // Trigger at HF 1.2
};

const partialSaleOrder = {
  title: orderTitle,
  interestRateMode: 2, // Variable rate
  collateralOut: [WETH_ADDRESS], // Give WETH to buyer
  percents: [10000], // 100% from WETH
  repayToken: USDC_ADDRESS, // Buyer pays with USDC
  repayAmount: ethers.parseUnits("3000", 6), // 3,000 USDC
  bonus: 200, // 2% bonus for buyer
  v: 0,
  r: ethers.ZeroHash,
  s: ethers.ZeroHash,
};

// Step 2: Create signature hash (matches contract verification)
// First, create the title hash
const titleHash = ethers.keccak256(
  ethers.AbiCoder.defaultAbiCoder().encode(
    ["bytes32", "address", "uint256", "uint256", "uint256", "uint256"],
    [
      await router.ORDER_TITLE_TYPE_HASH(),
      orderTitle.debt,
      orderTitle.debtNonce,
      orderTitle.startTime,
      orderTitle.endTime,
      orderTitle.triggerHF,
    ]
  )
);

// Then create the partial order struct hash
const structHash = ethers.keccak256(
  ethers.AbiCoder.defaultAbiCoder().encode(
    [
      "bytes32", // PARTIAL_SELL_ORDER_TYPE_HASH
      "uint256", // chainId
      "address", // contract
      "bytes32", // title hash
      "uint256", // interestRateMode
      "address[]", // collateralOut
      "uint256[]", // percents
      "address", // repayToken
      "uint256", // repayAmount
      "uint256", // bonus
    ],
    [
      await router.PARTIAL_SELL_ORDER_TYPE_HASH(),
      await provider.getNetwork().then((n) => n.chainId),
      await router.getAddress(),
      titleHash,
      partialSaleOrder.interestRateMode,
      partialSaleOrder.collateralOut,
      partialSaleOrder.percents,
      partialSaleOrder.repayToken,
      partialSaleOrder.repayAmount,
      partialSaleOrder.bonus,
    ]
  )
);

// Sign the struct hash directly (no EIP-712 domain)
const signature = await signer.signMessage(ethers.getBytes(structHash));
const { v, r, s } = ethers.Signature.from(signature);

partialSaleOrder.v = v;
partialSaleOrder.r = r;
partialSaleOrder.s = s;
```

### 💰 Order Execution Functions

#### 7. Execute Full Sale Order (Buyer)

**UI Use Case**: Buyer wants to purchase an entire debt position

**⚠️ SAFETY FIRST**: Always use multicall for atomic execution to prevent MEV attacks and ensure all operations succeed or fail together.

```javascript
// Step 1: Get current debt and collateral amounts BEFORE execution
const { totalCollateralBase, totalDebtBase } =
  await aavePool.getUserAccountData(order.title.debt);

// Get individual debt amounts
const daiDebt = await vDebtDAI.balanceOf(order.title.debt);
const usdcDebt = await vDebtUSDC.balanceOf(order.title.debt);

// Get individual collateral amounts
const wethAToken = await aavePool.getReserveData(WETH_ADDRESS);
const wethCollateral = await IERC20(wethAToken.aTokenAddress).balanceOf(
  order.title.debt
);

const wbtcAToken = await aavePool.getReserveData(WBTC_ADDRESS);
const wbtcCollateral = await IERC20(wbtcAToken.aTokenAddress).balanceOf(
  order.title.debt
);

// Step 2: Prepare approvals (do this BEFORE multicall)
// Calculate premium payment required
const netEquity = totalCollateralBase - totalDebtBase;
const premiumValue = (netEquity * order.percentOfEquity) / 10000;
const tokenPrice = await aaveOracle.getAssetPrice(order.token);
const premiumInTokens = await router._getTokenValueFromBaseValue(
  premiumValue,
  order.token,
  tokenPrice
);

// Approve tokens for the entire operation
await IERC20(order.token).approve(router.address, premiumInTokens); // For premium payment
await dai.approve(router.address, daiDebt); // For debt repayment
await usdc.approve(router.address, usdcDebt); // For debt repayment

// Step 3: Choose execution strategy and build multicall

// RECOMMENDED: Full cleanup strategy (safest)
const fullCleanupData = [
  // 1. Execute purchase (transfer ownership)
  router.interface.encodeFunctionData("executeFullSaleOrder", [
    order,
    0, // minProfit - set to 0 or calculate expected profit
  ]),

  // 2. Repay all DAI debt
  router.interface.encodeFunctionData("callRepay", [
    order.title.debt,
    DAI_ADDRESS,
    daiDebt,
    2, // Variable rate
  ]),

  // 3. Repay all USDC debt
  router.interface.encodeFunctionData("callRepay", [
    order.title.debt,
    USDC_ADDRESS,
    usdcDebt,
    2, // Variable rate
  ]),

  // 4. Withdraw all WETH to buyer
  router.interface.encodeFunctionData("callWithdraw", [
    order.title.debt,
    WETH_ADDRESS,
    wethCollateral,
    buyerAddress,
  ]),

  // 5. Withdraw all WBTC to buyer
  router.interface.encodeFunctionData("callWithdraw", [
    order.title.debt,
    WBTC_ADDRESS,
    wbtcCollateral,
    buyerAddress,
  ]),
];

// Execute everything atomically
await router.multicall(fullCleanupData);

// ALTERNATIVE: Strategic partial cleanup
const strategicCleanupData = [
  // Purchase
  router.interface.encodeFunctionData("executeFullSaleOrder", [order, 0]),

  // Repay only high-interest DAI debt
  router.interface.encodeFunctionData("callRepay", [
    order.title.debt,
    DAI_ADDRESS,
    daiDebt,
    2,
  ]),

  // Withdraw liquid WETH for immediate profit
  router.interface.encodeFunctionData("callWithdraw", [
    order.title.debt,
    WETH_ADDRESS,
    wethCollateral,
    buyerAddress,
  ]),

  // Keep USDC debt (lower interest) and WBTC collateral (potential upside)
  // Buyer can manage this later or let it appreciate
];

// MINIMAL: Purchase only (for advanced users)
const minimalData = [
  router.interface.encodeFunctionData("executeFullSaleOrder", [order, 0]),
];

// Step 4: Execute chosen strategy
await router.multicall(fullCleanupData); // or strategicCleanupData or minimalData
```

**UI Implementation Tips:**

```javascript
// Pre-execution validation
function validateExecution(order, userBalances, gasEstimate) {
  const checks = {
    hasEnoughTokens: userBalances[order.token] >= premiumRequired,
    hasEnoughGas: userBalance.eth >= gasEstimate,
    orderStillValid: currentTime <= order.title.endTime,
    healthFactorTriggered: currentHF <= order.title.triggerHF,
  };

  return Object.values(checks).every(Boolean);
}

// Gas estimation for different strategies
async function estimateExecutionGas(strategy, multicallData) {
  try {
    const gasEstimate = await router.estimateGas.multicall(multicallData);
    return {
      gasLimit: gasEstimate,
      gasPrice: await provider.getGasPrice(),
      totalCost: gasEstimate * gasPrice,
    };
  } catch (error) {
    throw new Error(`Execution would fail: ${error.message}`);
  }
}

// UI state management
const executionStrategies = {
  FULL_CLEANUP: {
    name: "Purchase + Full Cleanup",
    description: "Safest option - get all assets immediately",
    risk: "Low",
    gasMultiplier: 1.0,
  },
  STRATEGIC: {
    name: "Purchase + Strategic Cleanup",
    description: "Keep some position for potential upside",
    risk: "Medium",
    gasMultiplier: 0.7,
  },
  MINIMAL: {
    name: "Purchase Only",
    description: "Advanced users - manage position later",
    risk: "High",
    gasMultiplier: 0.3,
  },
};
```

#### 8. Execute Partial Sale Order (Buyer)

**UI Use Case**: Buyer wants to help someone and earn a bonus

```javascript
await router.excutePartialSellOrder(partialSaleOrder);
```

### 🔍 Data Fetching Functions

#### 9. Get Position Health Data

**UI Use Case**: Display current position status

```javascript
// Get comprehensive position data
const accountData = await aavePool.getUserAccountData(debtAddress);
const {
  totalCollateralBase,
  totalDebtBase,
  availableBorrowsBase,
  currentLiquidationThreshold,
  ltv,
  healthFactor,
} = accountData;

// Get individual token balances
const wethAToken = await aavePool.getReserveData(WETH_ADDRESS);
const wethCollateral = await IERC20(wethAToken.aTokenAddress).balanceOf(
  debtAddress
);

const usdcDebtToken = await aavePool.getReserveData(USDC_ADDRESS);
const usdcDebt = await IERC20(usdcDebtToken.variableDebtTokenAddress).balanceOf(
  debtAddress
);
```

#### 10. Check Order Validity

**UI Use Case**: Validate if an order can be executed

```javascript
// Check if order is still valid
const currentTime = Math.floor(Date.now() / 1000);
const isTimeValid =
  currentTime >= order.title.startTime && currentTime <= order.title.endTime;

// Check if debt nonce matches (order not cancelled)
const currentNonce = await router.debtNonces(order.title.debt);
const isNonceValid = currentNonce === order.title.debtNonce;

// Check if Health Factor is low enough
const { healthFactor } = await aavePool.getUserAccountData(order.title.debt);
const isHFTriggered = healthFactor <= order.title.triggerHF;

const canExecute = isTimeValid && isNonceValid && isHFTriggered;
```

### 🎛️ Administrative Functions

#### 11. Cancel Orders

**UI Use Case**: User wants to cancel all their current orders

```javascript
await router.cancelDebtCurrentOrders(debtAddress);
```

#### 12. Transfer Position Ownership

**UI Use Case**: User wants to transfer position to another address

```javascript
await router.transferDebtOwnership(debtAddress, newOwnerAddress);
```

### 📊 Price and Calculation Helpers

#### 13. Calculate Order Values

**UI Use Case**: Show users what they'll pay/receive

```javascript
// For Full Sale Orders - Calculate premium
const { totalCollateralBase, totalDebtBase } =
  await aavePool.getUserAccountData(debtAddress);
const netEquity = totalCollateralBase - totalDebtBase;
const premiumValue = (netEquity * order.percentOfEquity) / 10000;

// Convert to token amount
const tokenPrice = await aaveOracle.getAssetPrice(order.token);
const premiumInTokens = await router._getTokenValueFromBaseValue(
  premiumValue,
  order.token,
  tokenPrice
);

// For Partial Sale Orders - Calculate collateral to receive
const repayValueInBase = await router._getBaseValueFromTokenValue(
  order.repayToken,
  order.repayAmount,
  await aaveOracle.getAssetPrice(order.repayToken)
);

const collateralValue = (repayValueInBase * (10000 + order.bonus)) / 10000;
```

### 🔄 Error Handling for Function Calls

#### Common Errors and Solutions

```javascript
try {
  await router.executeFullSaleOrder(order, minProfit);
} catch (error) {
  if (error.message.includes("HF too high")) {
    showError("Position not risky enough yet - monitor and wait");
  } else if (error.message.includes("Order expired")) {
    showError("This order has expired - create a new order");
  } else if (error.message.includes("Invalid signature")) {
    showError("Order signature invalid - please re-sign");
  } else if (error.message.includes("Insufficient profit")) {
    showError("Not enough profit for buyer - adjust parameters");
  }
}
```

### 📱 Contract Addresses and ABIs

Your UI will need these contract addresses and ABIs:

```javascript
// Contract addresses (update for your deployment)
const ROUTER_ADDRESS = "0x..."; // Your AaveRouter deployment
const AAVE_POOL_ADDRESS = "0x..."; // Aave V3 Pool
const AAVE_ORACLE_ADDRESS = "0x..."; // Aave Price Oracle

// Token addresses (mainnet examples)
const WETH_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const WBTC_ADDRESS = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599";
const USDC_ADDRESS = "0xA0b86a33E6441b8C4505B8C4505B8C4505B8C4505";
const DAI_ADDRESS = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

// You'll need ABIs for:
// - AaveRouter.sol
// - IPool.sol (Aave V3)
// - IPriceOracleGetter.sol (Aave V3)
// - IERC20.sol (for token interactions)
```

### 🔐 Signature Helper Functions

The contract uses specific TYPE_HASH constants for signature verification. Here are helper functions:

```javascript
// TYPE_HASH constants (these match the contract exactly)
const ORDER_TITLE_TYPE_HASH =
  "0x" +
  ethers
    .keccak256(
      ethers.toUtf8Bytes(
        "OrderTitle(address debt,uint256 debtNonce,uint256 startTime,uint256 endTime,uint256 triggerHF)"
      )
    )
    .slice(2);

const FULL_SELL_ORDER_TYPE_HASH =
  "0x" +
  ethers
    .keccak256(
      ethers.toUtf8Bytes(
        "FullSellOrder(uint256 chainId,address contract,OrderTitle title,address token,uint256 percentOfEquity)"
      )
    )
    .slice(2);

const PARTIAL_SELL_ORDER_TYPE_HASH =
  "0x" +
  ethers
    .keccak256(
      ethers.toUtf8Bytes(
        "PartialSellOrder(uint256 chainId,address contract,OrderTitle title,uint256 interestRateMode,address[] collateralOut,uint256[] percents,address repayToken,uint256 repayAmount,uint256 bonus)"
      )
    )
    .slice(2);

// Helper function to create title hash
async function createTitleHash(orderTitle, router) {
  return ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "address", "uint256", "uint256", "uint256", "uint256"],
      [
        await router.ORDER_TITLE_TYPE_HASH(), // Or use ORDER_TITLE_TYPE_HASH constant
        orderTitle.debt,
        orderTitle.debtNonce,
        orderTitle.startTime,
        orderTitle.endTime,
        orderTitle.triggerHF,
      ]
    )
  );
}

// Helper function to sign full sale order
async function signFullSaleOrder(fullSaleOrder, signer, router, provider) {
  const titleHash = await createTitleHash(fullSaleOrder.title, router);

  const structHash = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "uint256", "address", "bytes32", "address", "uint256"],
      [
        await router.FULL_SELL_ORDER_TYPE_HASH(),
        await provider.getNetwork().then((n) => n.chainId),
        await router.getAddress(),
        titleHash,
        fullSaleOrder.token,
        fullSaleOrder.percentOfEquity,
      ]
    )
  );

  const signature = await signer.signMessage(ethers.getBytes(structHash));
  const { v, r, s } = ethers.Signature.from(signature);

  return { v, r, s };
}

// Helper function to sign partial sale order
async function signPartialSaleOrder(
  partialSaleOrder,
  signer,
  router,
  provider
) {
  const titleHash = await createTitleHash(partialSaleOrder.title, router);

  const structHash = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      [
        "bytes32",
        "uint256",
        "address",
        "bytes32",
        "uint256",
        "address[]",
        "uint256[]",
        "address",
        "uint256",
        "uint256",
      ],
      [
        await router.PARTIAL_SELL_ORDER_TYPE_HASH(),
        await provider.getNetwork().then((n) => n.chainId),
        await router.getAddress(),
        titleHash,
        partialSaleOrder.interestRateMode,
        partialSaleOrder.collateralOut,
        partialSaleOrder.percents,
        partialSaleOrder.repayToken,
        partialSaleOrder.repayAmount,
        partialSaleOrder.bonus,
      ]
    )
  );

  const signature = await signer.signMessage(ethers.getBytes(structHash));
  const { v, r, s } = ethers.Signature.from(signature);

  return { v, r, s };
}

// Usage example:
const { v, r, s } = await signFullSaleOrder(
  fullSaleOrder,
  signer,
  router,
  provider
);
fullSaleOrder.v = v;
fullSaleOrder.r = r;
fullSaleOrder.s = s;
```

## 👥 User Roles

### 1. Position Holders (Sellers)

Users who own debt positions and want to:

- Create sale orders when their Health Factor becomes risky
- Preserve equity value while avoiding liquidation
- Transfer position ownership for a premium

### 2. Debt Buyers

Users who want to:

- Acquire profitable debt positions
- Help others avoid liquidation while earning returns
- Manage acquired positions post-purchase

## 📋 Core Data Structures

### OrderTitle (Common to All Orders)

```solidity
struct OrderTitle {
    address debt;        // The debt contract address
    uint256 debtNonce;   // Current nonce of the debt position
    uint256 startTime;   // When the order becomes active
    uint256 endTime;     // When the order expires
    uint256 triggerHF;   // Health Factor threshold for execution
}
```

**UI Parameter Explanations:**

| Parameter   | User-Friendly Name | Description                                       | UI Input Type           |
| ----------- | ------------------ | ------------------------------------------------- | ----------------------- |
| `debt`      | Position Address   | The unique address of your debt position          | Auto-filled (read-only) |
| `debtNonce` | Position Version   | Current version number (prevents replay attacks)  | Auto-filled (read-only) |
| `startTime` | Order Start Time   | When buyers can start executing this order        | DateTime picker         |
| `endTime`   | Order Expiry       | When this order automatically expires             | DateTime picker         |
| `triggerHF` | Danger Threshold   | Health Factor level that triggers order execution | Slider (1.0 - 2.0)      |

**UI Recommendations:**

- **Danger Threshold**: Use color-coded slider (Red: 1.0-1.2, Yellow: 1.2-1.5, Green: 1.5+)
- **Time Inputs**: Default to "Active Now" and "7 days from now"
- **Position Info**: Show current HF and risk level prominently

## 🔄 Full Sale Orders

### Data Structure

```solidity
struct FullSellOrder {
    OrderTitle title;           // Order metadata
    address token;              // Payment token for premium
    uint256 percentOfEquity;    // Percentage of net equity going to seller
    uint8 v; bytes32 r; bytes32 s;  // Signature components
}
```

### Parameter Details

| Parameter         | User-Friendly Name | Description                              | UI Input Type   | Recommended Values |
| ----------------- | ------------------ | ---------------------------------------- | --------------- | ------------------ |
| `token`           | Payment Currency   | Token buyer uses to pay the premium      | Token selector  | WBTC, WETH, USDC   |
| `percentOfEquity` | Equity Share       | Percentage of your equity you'll receive | Slider (0-100%) | 70-95%             |

### UI Workflow for Sellers

#### Step 1: Position Analysis

```
┌─────────────────────────────────────┐
│ Your Position Summary               │
├─────────────────────────────────────┤
│ Total Collateral: $50,000          │
│ Total Debt: $25,500                │
│ Net Equity: $24,500                │
│ Current Health Factor: 1.2 ⚠️       │
│ Risk Level: DANGEROUS               │
└─────────────────────────────────────┘
```

#### Step 2: Order Configuration

```
┌─────────────────────────────────────┐
│ Create Full Sale Order              │
├─────────────────────────────────────┤
│ Equity Share: [████████░░] 80%      │
│ You'll receive: $19,600             │
│ Buyer gets: $4,900 profit + ownership│
│                                     │
│ Payment Currency: [WBTC ▼]          │
│ Danger Threshold: [███░░░░] 1.1     │
│ Order Duration: [7 days ▼]          │
│                                     │
│ [Preview Order] [Create & Sign]     │
└─────────────────────────────────────┘
```

#### Step 3: Order Preview

```
┌─────────────────────────────────────┐
│ Order Preview                       │
├─────────────────────────────────────┤
│ When Health Factor drops to 1.1:   │
│ • You receive: 0.32 WBTC (~$19,600) │
│ • Buyer pays: 0.78 WBTC total      │
│ • Buyer gets: Position ownership    │
│ • Buyer profit: ~$4,900 (20%)      │
│                                     │
│ ⚠️ You'll lose position ownership   │
│ ✅ You'll preserve 80% of equity    │
│                                     │
│ [Confirm & Sign] [Edit Order]       │
└─────────────────────────────────────┘
```

### UI Workflow for Buyers

#### Step 1: Order Discovery

```
┌─────────────────────────────────────┐
│ Available Full Sale Orders          │
├─────────────────────────────────────┤
│ Position #1                         │
│ Collateral: $45K | Debt: $30K      │
│ Your Profit: $3K (20%) | HF: 1.05  │
│ Payment: 0.5 WBTC | Status: READY  │
│ [Execute Order]                     │
│                                     │
│ Position #2                         │
│ Collateral: $80K | Debt: $50K      │
│ Your Profit: $6K (20%) | HF: 1.15  │
│ Payment: 1.2 WBTC | Status: WAITING│
│ [Monitor]                           │
└─────────────────────────────────────┘
```

#### Step 2: Execution Options

```
┌─────────────────────────────────────┐
│ Execute Full Sale Order             │
├─────────────────────────────────────┤
│ Required Payment: 0.5 WBTC          │
│ Your Balance: 2.1 WBTC ✅           │
│                                     │
│ After Purchase:                     │
│ • You own the entire position       │
│ • Immediate profit: $3,000          │
│ • Position value: $45,000           │
│ • Outstanding debt: $30,000         │
│                                     │
│ Post-Purchase Actions (Optional):   │
│ ☐ Repay all debts immediately       │
│ ☐ Withdraw all collateral           │
│ ☐ Keep position for management      │
│                                     │
│ [Execute Purchase Only]             │
│ [Execute + Full Cleanup]            │
└─────────────────────────────────────┘
```

### 🔑 Key UI Insight: Optional Post-Execution Steps

**Important**: After `executeFullSaleOrder`, the buyer owns the position but **all subsequent actions are optional and buyer-controlled**.

**⚠️ SAFETY RECOMMENDATION**: Use multicall to execute everything in one transaction to prevent MEV attacks and ensure atomicity.

```javascript
// RECOMMENDED: Execute everything in one safe transaction using multicall
const multicallData = [
  // REQUIRED: Execute the purchase (transfer ownership)
  router.interface.encodeFunctionData("executeFullSaleOrder", [
    order,
    0, // minProfit
  ]),

  // OPTIONAL: Choose your post-purchase strategy
  // Option 1: Full cleanup (repay all debts + withdraw all collateral)
  router.interface.encodeFunctionData("callRepay", [
    order.title.debt,
    DAI_ADDRESS,
    daiDebtAmount, // Get from getUserAccountData before execution
    2, // Variable rate
  ]),

  router.interface.encodeFunctionData("callRepay", [
    order.title.debt,
    USDC_ADDRESS,
    usdcDebtAmount,
    2,
  ]),

  router.interface.encodeFunctionData("callWithdraw", [
    order.title.debt,
    WETH_ADDRESS,
    wethCollateralAmount,
    buyerAddress,
  ]),

  router.interface.encodeFunctionData("callWithdraw", [
    order.title.debt,
    WBTC_ADDRESS,
    wbtcCollateralAmount,
    buyerAddress,
  ]),
];

// Execute all operations atomically
await router.multicall(multicallData);

// Alternative strategies (choose one):

// Option 2: Purchase + Partial cleanup (keep some debt/collateral)
const partialCleanupData = [
  // Purchase
  router.interface.encodeFunctionData("executeFullSaleOrder", [order, 0]),

  // Repay only high-interest debt
  router.interface.encodeFunctionData("callRepay", [
    order.title.debt,
    DAI_ADDRESS,
    daiDebtAmount,
    2,
  ]),

  // Withdraw only WETH (keep WBTC as collateral)
  router.interface.encodeFunctionData("callWithdraw", [
    order.title.debt,
    WETH_ADDRESS,
    wethCollateralAmount,
    buyerAddress,
  ]),
  // Keep USDC debt and WBTC collateral for ongoing management
];

// Option 3: Purchase only (minimal execution)
const minimalData = [
  router.interface.encodeFunctionData("executeFullSaleOrder", [order, 0]),
  // Buyer can manage position later through separate transactions
];
```

**UI Design Implications:**

- **Primary Button**: "Execute Purchase + Full Cleanup" (safest option)
- **Secondary Button**: "Execute Purchase Only" (for advanced users)
- **Advanced Options**: Custom multicall builder for partial cleanup
- **Safety Warning**: Emphasize single-transaction execution benefits
- **Gas Estimation**: Show total gas cost for the entire multicall

## 🔄 Partial Sale Orders

### Data Structure

```solidity
struct PartialSellOrder {
    OrderTitle title;
    uint256 interestRateMode;   // Type of debt to repay (1=stable, 2=variable)
    address[] collateralOut;    // Which collateral tokens to withdraw
    uint256[] percents;         // Percentage allocation for each collateral
    address repayToken;         // Token buyer uses for debt repayment
    uint256 repayAmount;        // Amount of debt to repay
    uint256 bonus;              // Bonus percentage for buyer
    uint8 v; bytes32 r; bytes32 s;
}
```

### Parameter Details

| Parameter          | User-Friendly Name | Description                             | UI Input Type     | Example                     |
| ------------------ | ------------------ | --------------------------------------- | ----------------- | --------------------------- |
| `interestRateMode` | Debt Type          | Which type of debt to repay             | Radio buttons     | Variable Rate (recommended) |
| `collateralOut`    | Collateral to Give | Which assets buyer receives             | Multi-select      | [WETH, WBTC]                |
| `percents`         | Allocation Split   | How to split payment across collaterals | Percentage inputs | [70%, 30%]                  |
| `repayToken`       | Repayment Currency | Token buyer uses to repay your debt     | Token selector    | USDC                        |
| `repayAmount`      | Help Amount        | How much debt buyer will repay          | Amount input      | $5,000                      |
| `bonus`            | Buyer Bonus        | Extra reward for helping you            | Slider (0-10%)    | 2%                          |

### UI Workflow for Sellers

#### Step 1: Help Request Configuration

```
┌─────────────────────────────────────┐
│ Request Partial Sale Help           │
├─────────────────────────────────────┤
│ Your Situation:                     │
│ Health Factor: 1.2 ⚠️ (Risky)       │
│ Need help to reach: 1.5 ✅ (Safe)   │
│                                     │
│ Request Details:                    │
│ Help Amount: $5,000 USDC            │
│ Debt Type: Variable Rate ●          │
│                                     │
│ What you'll give in return:         │
│ WETH: [████████░░] 80% ($4,000)     │
│ WBTC: [██░░░░░░░░] 20% ($1,000)     │
│ Buyer Bonus: [██░░░░░░░░] 2% ($100) │
│                                     │
│ Total to buyer: $5,100              │
│ Your HF improvement: 1.2 → 1.5      │
│                                     │
│ [Create Help Request]               │
└─────────────────────────────────────┘
```

### UI Workflow for Buyers

#### Step 1: Help Opportunities

```
┌─────────────────────────────────────┐
│ Help Others & Earn                  │
├─────────────────────────────────────┤
│ Request #1                          │
│ Pay: $3,000 USDC                   │
│ Get: $3,060 value (2% bonus)       │
│ Assets: WETH only                   │
│ Risk: Low (HF: 1.2 → 1.4)          │
│ [Help Now]                          │
│                                     │
│ Request #2                          │
│ Pay: $8,000 USDC                   │
│ Get: $8,400 value (5% bonus)       │
│ Assets: Mixed WETH/WBTC             │
│ Risk: Medium (HF: 1.1 → 1.3)       │
│ [Help Now]                          │
└─────────────────────────────────────┘
```

## 🎨 UI/UX Best Practices

### 1. Health Factor Visualization

```
Health Factor: 1.23
[████████░░░░░░░░░░]
🔴 Danger  🟡 Caution  🟢 Safe
1.0        1.5         2.0+

Status: ⚠️ CAUTION - Consider creating sale orders
```

### 2. Risk Communication

**For Sellers:**

- ❌ "You will lose your position" (Full Sale)
- ✅ "Your Health Factor will improve" (Partial Sale)
- 💰 "You'll preserve X% of your equity"

**For Buyers:**

- 💰 "Immediate profit: $X"
- 📈 "Position value: $Y"
- ⚠️ "Outstanding debt: $Z"

### 3. Transaction Flow

```
Step 1: Review → Step 2: Sign → Step 3: Execute → Step 4: Manage (Optional)
```

### 4. Error Handling

Common error scenarios and user-friendly messages:

| Error                  | User Message                    | Suggested Action             |
| ---------------------- | ------------------------------- | ---------------------------- |
| `HF too high`          | "Position not risky enough yet" | "Monitor and wait"           |
| `Order expired`        | "This order has expired"        | "Create new order"           |
| `Insufficient balance` | "Not enough tokens to execute"  | "Add funds or reduce amount" |
| `Invalid signature`    | "Order signature invalid"       | "Re-sign the order"          |

### 5. Mobile Considerations

- **Simplified Parameter Entry**: Use sliders and presets
- **Clear Visual Hierarchy**: Most important info first
- **Touch-Friendly Controls**: Large buttons and inputs
- **Progressive Disclosure**: Show advanced options on demand

## 🔐 Security & Trust Indicators

### Order Verification

```
┌─────────────────────────────────────┐
│ Order Verification ✅               │
├─────────────────────────────────────┤
│ ✅ Signature valid                  │
│ ✅ Order not expired                │
│ ✅ Position exists                  │
│ ✅ Health Factor in range           │
│ ⚠️ High bonus rate (review carefully)│
└─────────────────────────────────────┘
```

### Transaction Preview

```
┌─────────────────────────────────────┐
│ Transaction Preview                 │
├─────────────────────────────────────┤
│ You will send: 0.5 WBTC             │
│ You will receive: Position ownership │
│ Estimated gas: ~$25                 │
│ Network: Ethereum Mainnet           │
│                                     │
│ ⚠️ This action cannot be undone     │
│                                     │
│ [Confirm Transaction]               │
└─────────────────────────────────────┘
```

## 📱 Responsive Design Guidelines

### Desktop Layout

- **Left Panel**: Position list/order book
- **Center Panel**: Order details and execution
- **Right Panel**: User portfolio and notifications

### Mobile Layout

- **Tab Navigation**: Positions | Orders | Portfolio
- **Card-Based Design**: Each order/position as a card
- **Bottom Sheet**: Order execution details

## 🎯 User Onboarding

### First-Time Sellers

1. **Education**: "What is a debt position?"
2. **Risk Assessment**: "When should you create sale orders?"
3. **Parameter Guidance**: "How to set equity percentage?"
4. **Safety Tips**: "Understanding Health Factor"

### First-Time Buyers

1. **Opportunity Explanation**: "How debt buying works"
2. **Profit Calculation**: "Understanding your returns"
3. **Risk Assessment**: "Evaluating positions"
4. **Post-Purchase Options**: "Managing acquired positions"

## 🔄 Real-Time Updates

### WebSocket Events

- Health Factor changes
- Order status updates
- New order notifications
- Execution confirmations

### Notification Types

- 🔴 "Your HF dropped below 1.2"
- 🟡 "Order expires in 2 hours"
- 🟢 "Your order was executed"
- 💰 "New profitable opportunity available"

---

This documentation provides the foundation for building intuitive, user-friendly interfaces that make debt trading accessible to both experienced DeFi users and newcomers to the space.

### 🛡️ Safety Best Practices for Multicall Execution

#### Critical Safety Considerations

```javascript
// 1. ALWAYS validate before execution
async function safeExecuteOrder(order, strategy = "FULL_CLEANUP") {
  // Pre-execution checks
  const validation = await validateOrderExecution(order);
  if (!validation.isValid) {
    throw new Error(`Cannot execute: ${validation.errors.join(", ")}`);
  }

  // Get fresh data right before execution
  const positionData = await getPositionData(order.title.debt);

  // Build multicall based on current state
  const multicallData = buildMulticallData(order, positionData, strategy);

  // Estimate gas and validate
  const gasEstimate = await router.estimateGas.multicall(multicallData);

  // Execute with proper error handling
  try {
    const tx = await router.multicall(multicallData, {
      gasLimit: gasEstimate.mul(110).div(100), // 10% buffer
    });

    return await tx.wait();
  } catch (error) {
    throw new Error(`Execution failed: ${parseExecutionError(error)}`);
  }
}

// 2. Validation function
async function validateOrderExecution(order) {
  const errors = [];

  // Check order validity
  const currentTime = Math.floor(Date.now() / 1000);
  if (currentTime > order.title.endTime) {
    errors.push("Order has expired");
  }

  // Check Health Factor trigger
  const { healthFactor } = await aavePool.getUserAccountData(order.title.debt);
  if (healthFactor > order.title.triggerHF) {
    errors.push("Health Factor not low enough to trigger");
  }

  // Check debt nonce (order not cancelled)
  const currentNonce = await router.debtNonces(order.title.debt);
  if (currentNonce !== order.title.debtNonce) {
    errors.push("Order has been cancelled");
  }

  // Check signature validity
  const isValidSignature = await router._verifyFullSellOrder(order, seller);
  if (!isValidSignature) {
    errors.push("Invalid order signature");
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// 3. Dynamic multicall builder
function buildMulticallData(order, positionData, strategy) {
  const data = [
    // Always start with the purchase
    router.interface.encodeFunctionData("executeFullSaleOrder", [order, 0]),
  ];

  if (strategy === "FULL_CLEANUP") {
    // Add all debt repayments
    positionData.debts.forEach((debt) => {
      if (debt.amount > 0) {
        data.push(
          router.interface.encodeFunctionData("callRepay", [
            order.title.debt,
            debt.token,
            debt.amount,
            debt.rateMode,
          ])
        );
      }
    });

    // Add all collateral withdrawals
    positionData.collaterals.forEach((collateral) => {
      if (collateral.amount > 0) {
        data.push(
          router.interface.encodeFunctionData("callWithdraw", [
            order.title.debt,
            collateral.token,
            collateral.amount,
            buyerAddress,
          ])
        );
      }
    });
  }

  return data;
}

// 4. Error parsing for user-friendly messages
function parseExecutionError(error) {
  if (error.message.includes("HF too high")) {
    return "Position Health Factor is not risky enough yet";
  }
  if (error.message.includes("Order expired")) {
    return "This order has expired";
  }
  if (error.message.includes("Invalid signature")) {
    return "Order signature is invalid";
  }
  if (error.message.includes("Insufficient profit")) {
    return "Not enough profit for this purchase";
  }
  return error.message;
}
```

#### UI Safety Features

```javascript
// 1. Transaction preview with safety checks
function TransactionPreview({ order, strategy }) {
  const [preview, setPreview] = useState(null);
  const [risks, setRisks] = useState([]);

  useEffect(() => {
    async function generatePreview() {
      const positionData = await getPositionData(order.title.debt);
      const multicallData = buildMulticallData(order, positionData, strategy);
      const gasEstimate = await estimateGas(multicallData);

      // Calculate expected outcomes
      const expectedProfit = calculateExpectedProfit(order, positionData);
      const riskAssessment = assessRisks(order, positionData, strategy);

      setPreview({
        totalGasCost: gasEstimate.totalCost,
        expectedProfit,
        netProfit: expectedProfit - gasEstimate.totalCost,
        operations: multicallData.length,
      });

      setRisks(riskAssessment);
    }

    generatePreview();
  }, [order, strategy]);

  return (
    <div className="transaction-preview">
      <h3>Transaction Preview</h3>

      {/* Safety indicators */}
      <div className="safety-checks">
        <SafetyIndicator check="orderValid" status={preview?.orderValid} />
        <SafetyIndicator
          check="healthFactorTriggered"
          status={preview?.hfTriggered}
        />
        <SafetyIndicator
          check="sufficientBalance"
          status={preview?.hasBalance}
        />
      </div>

      {/* Financial summary */}
      <div className="financial-summary">
        <div>Expected Profit: ${preview?.expectedProfit}</div>
        <div>Gas Cost: ${preview?.totalGasCost}</div>
        <div>Net Profit: ${preview?.netProfit}</div>
      </div>

      {/* Risk warnings */}
      {risks.length > 0 && (
        <div className="risk-warnings">
          {risks.map((risk) => (
            <RiskWarning key={risk.type} risk={risk} />
          ))}
        </div>
      )}

      {/* Execution button */}
      <button
        onClick={() => safeExecuteOrder(order, strategy)}
        disabled={!preview?.canExecute}
        className="execute-button"
      >
        Execute {strategy.replace("_", " ")} ({preview?.operations} operations)
      </button>
    </div>
  );
}

// 2. Real-time monitoring during execution
function ExecutionMonitor({ txHash }) {
  const [status, setStatus] = useState("pending");
  const [operations, setOperations] = useState([]);

  useEffect(() => {
    async function monitorExecution() {
      const receipt = await provider.waitForTransaction(txHash);

      if (receipt.status === 1) {
        setStatus("success");
        // Parse logs to show which operations succeeded
        const parsedLogs = parseMulticallLogs(receipt.logs);
        setOperations(parsedLogs);
      } else {
        setStatus("failed");
      }
    }

    monitorExecution();
  }, [txHash]);

  return (
    <div className="execution-monitor">
      <div className="status">Status: {status}</div>
      {operations.map((op, i) => (
        <div key={i} className="operation">
          ✅ {op.name}: {op.result}
        </div>
      ))}
    </div>
  );
}
```

#### MEV Protection Strategies

```javascript
// 1. Slippage protection
function addSlippageProtection(multicallData, maxSlippage = 0.5) {
  // Add minProfit parameter to executeFullSaleOrder
  const originalExecute = multicallData[0];
  const decodedExecute = router.interface.decodeFunctionData(
    "executeFullSaleOrder",
    originalExecute
  );

  // Calculate minimum acceptable profit
  const expectedProfit = calculateExpectedProfit(decodedExecute.order);
  const minProfit = expectedProfit * (1 - maxSlippage / 100);

  // Update with slippage protection
  multicallData[0] = router.interface.encodeFunctionData(
    "executeFullSaleOrder",
    [decodedExecute.order, minProfit]
  );

  return multicallData;
}

// 2. Deadline protection
function addDeadlineProtection(order, maxDelay = 300) {
  // 5 minutes
  const deadline = Math.floor(Date.now() / 1000) + maxDelay;

  if (deadline > order.title.endTime) {
    throw new Error("Order expires too soon for safe execution");
  }

  return deadline;
}

// 3. Front-running detection
async function detectFrontRunning(order) {
  const currentBlock = await provider.getBlockNumber();
  const { healthFactor } = await aavePool.getUserAccountData(order.title.debt);

  // Check if HF changed significantly in recent blocks
  const historicalHF = await getHistoricalHealthFactor(
    order.title.debt,
    currentBlock - 5
  );
  const hfChange = Math.abs(healthFactor - historicalHF) / historicalHF;

  if (hfChange > 0.1) {
    // 10% change
    return {
      detected: true,
      message:
        "Significant Health Factor change detected - possible front-running",
    };
  }

  return { detected: false };
}
```
