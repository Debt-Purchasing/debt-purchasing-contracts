# Aave V3 Mainnet Configuration Analysis

## Overview

This document contains the real configurations extracted from Aave V3 mainnet via fork testing, providing accurate parameters for Sepolia deployment.

## Key Findings

### 1. **Price Data (Current Market Prices)**

- **WETH**: $2,562.92
- **wstETH**: $2,956.49 (premium over WETH)
- **WBTC**: $42,825.87
- **USDC**: $1.00
- **DAI**: $0.99 (slight depeg)
- **LINK**: $14.21
- **AAVE**: $106.47
- **cbETH**: $2,711.07 (premium over WETH)
- **USDT**: $0.99 (slight depeg)
- **rETH**: $2,807.10 (highest ETH premium)
- **LUSD**: $1.00
- **CRV**: $0.55

### 2. **Risk Parameters Comparison**

| Token  | LTV (Our vs Real) | Liquidation Threshold (Our vs Real) | Liquidation Bonus (Our vs Real) |
| ------ | ----------------- | ----------------------------------- | ------------------------------- |
| WETH   | 80% vs **80.5%**  | 82.5% vs **83%**                    | 105% vs **105%** ✅             |
| wstETH | 75% vs **78.5%**  | 80% vs **81%**                      | 107% vs **106%**                |
| WBTC   | 70% vs **73%**    | 75% vs **78%**                      | 110% vs **105%**                |
| USDC   | 87% vs **77%**    | 89% vs **80%**                      | 104% vs **104.5%**              |
| DAI    | 86% vs **77%**    | 88% vs **80%**                      | 105% vs **105%** ✅             |
| LINK   | 70% vs **53%**    | 75% vs **68%**                      | 110% vs **107%**                |
| AAVE   | 66% vs **66%** ✅ | 73% vs **73%** ✅                   | 115% vs **107.5%**              |
| cbETH  | 74% vs **74.5%**  | 77% vs **77%** ✅                   | 107.5% vs **107.5%** ✅         |
| USDT   | 86% vs **74%**    | 88% vs **76%**                      | 105% vs **104.5%**              |
| rETH   | 67% vs **74.5%**  | 74% vs **77%**                      | Not set vs **107.5%**           |
| LUSD   | 80% vs **77%**    | 85% vs **80%**                      | Not set vs **104.5%**           |
| CRV    | 55% vs **35%**    | 61% vs **41%**                      | Not set vs **108.3%**           |

### 3. **Interest Rate Strategy Analysis**

#### **Stablecoin Strategy (USDC, DAI, USDT, LUSD)**

- **Optimal Usage**: 90% (real) vs 90% (our estimate) ✅
- **Variable Rate Slope 1**: 5% (real) vs 3.5% (our estimate)
- **Variable Rate Slope 2**: 60-87% (real) vs 60-75% (our estimate)

#### **ETH Strategy (WETH, wstETH, cbETH, rETH)**

- **Optimal Usage**: 45-80% (real) vs 80-45% (our estimate)
- **WETH**: Uses 80% optimal (more aggressive than other ETH assets)
- **Others**: Use 45% optimal (conservative approach)

#### **BTC Strategy (WBTC)**

- **Optimal Usage**: 45% (real) vs 45% (our estimate) ✅
- **Variable Rate Slope 2**: 300% (real) vs 300% (our estimate) ✅

#### **Altcoin Strategy (LINK, AAVE, CRV)**

- **Optimal Usage**: 45-70% (real) vs 45% (our estimate)
- **Variable Rate Slope 1**: 7-14% (real) vs 4.5% (our estimate)

### 4. **Major Differences Found**

#### **Conservative vs Aggressive Approach**

- **Our approach**: More conservative LTV/Liquidation ratios for safety
- **Mainnet approach**: More aggressive ratios, especially for stablecoins

#### **Stablecoin Configurations**

- **USDC/DAI/USDT**: Mainnet uses much lower LTV (77% vs our 86-87%)
- **Reason**: Recent depegging events and regulatory concerns

#### **AAVE Token Borrowing**

- **Real**: Borrowing **DISABLED** on mainnet
- **Our config**: Had borrowing enabled
- **Supply cap**: 1.85M AAVE vs unlimited in our config

#### **CRV Token Risk**

- **Real**: Very conservative (35% LTV, 41% threshold)
- **Our config**: Too aggressive (55% LTV, 61% threshold)
- **Reason**: CRV is considered high-risk volatile asset

### 5. **Reserve Factor Analysis**

| Token       | Our Reserve Factor | Real Reserve Factor | Notes                   |
| ----------- | ------------------ | ------------------- | ----------------------- |
| WETH        | 10%                | **15%**             | Higher protocol revenue |
| wstETH      | 15%                | **15%** ✅          | Matches perfectly       |
| WBTC        | 20%                | **20%** ✅          | Matches perfectly       |
| Stablecoins | 10%                | **10%** ✅          | Standard rate           |
| AAVE        | 0%                 | **0%** ✅           | No protocol fee         |
| CRV         | Not set            | **35%**             | Very high due to risk   |

### 6. **Supply/Borrow Caps (Real Mainnet)**

| Token  | Supply Cap | Borrow Cap | Notes                  |
| ------ | ---------- | ---------- | ---------------------- |
| WETH   | 1.8M       | 1.4M       | Large market           |
| wstETH | 1.1M       | 24K        | Limited borrowing      |
| WBTC   | 43K        | 28K        | Bitcoin exposure       |
| USDC   | 1.76B      | 1.58B      | Largest market         |
| DAI    | 338M       | 271M       | Large stable market    |
| LINK   | 15M        | 13M        | Chainlink exposure     |
| AAVE   | 1.85M      | **0**      | No borrowing allowed   |
| cbETH  | 60K        | 2.4K       | Very limited borrowing |
| USDT   | 800M       | 750M       | Large stable market    |
| rETH   | 90K        | 19.2K      | Limited borrowing      |
| LUSD   | 18M        | 8M         | Moderate stable market |
| CRV    | 10M        | 5M         | High-risk altcoin      |

## Recommendations for Sepolia Deployment

### 1. **Update Risk Parameters**

```solidity
// More accurate mainnet-like configurations
USDC: ltv: 7700, liquidationThreshold: 8000, // Reduced from 87%/89%
DAI: ltv: 7700, liquidationThreshold: 8000,  // Reduced from 86%/88%
USDT: ltv: 7400, liquidationThreshold: 7600, // Reduced from 86%/88%
AAVE: borrowingEnabled: false,                // Disable borrowing
CRV: ltv: 3500, liquidationThreshold: 4100,  // Much more conservative
```

### 2. **Update Interest Rate Strategies**

```solidity
// Stablecoin strategy - higher base rates
variableRateSlope1: 0.05e27, // 5% instead of 3.5%

// ETH strategy - differentiate WETH vs others
WETH: optimalUsageRatio: 0.8e27,  // 80% like mainnet
Others: optimalUsageRatio: 0.45e27, // 45% for staked ETH
```

### 3. **Set Appropriate Caps**

```solidity
// Implement realistic supply/borrow caps
// Especially important for staked ETH assets (wstETH, cbETH, rETH)
// These should have limited borrowing capabilities
```

### 4. **Current Price Updates**

Use current market prices instead of outdated estimates:

- WETH: $2,563 (not $2,000)
- WBTC: $42,826 (not $60,000)
- AAVE: $106 (not $80)

## Implementation Priority

### **High Priority** 🔴

1. Disable AAVE borrowing
2. Reduce stablecoin LTV to 77%
3. Make CRV much more conservative (35% LTV)
4. Update current market prices

### **Medium Priority** 🟡

1. Adjust interest rate strategies
2. Implement supply/borrow caps
3. Fine-tune liquidation bonuses

### **Low Priority** 🟢

1. Minor LTV adjustments for ETH assets
2. Reserve factor optimizations

## Conclusion

The mainnet analysis reveals that our initial configurations were generally in the right direction but need significant adjustments, particularly:

- **Stablecoins**: Much more conservative than we estimated
- **AAVE**: Borrowing completely disabled
- **CRV**: Extremely conservative risk parameters
- **Interest rates**: Higher base rates for stablecoins

These findings will help create a more production-accurate Sepolia deployment for reliable testing of the debt purchasing protocol.
