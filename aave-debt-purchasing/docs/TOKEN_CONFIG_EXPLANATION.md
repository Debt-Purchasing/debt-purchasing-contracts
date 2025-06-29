# TokenConfig Parameters và Aave V3 Structs Mapping

## 📋 Tổng quan

Tài liệu này giải thích chi tiết ý nghĩa của từng tham số trong `TokenConfig` và cách chúng map với các struct của Aave V3 core.

## 🔧 TokenConfig Structure

```solidity
struct TokenConfig {
    string name;                        // Tên token đầy đủ
    string symbol;                      // Symbol token
    uint8 decimals;                     // Số decimals
    int256 initialPrice;                // Giá khởi tạo (Chainlink format)
    uint256 ltv;                        // Loan to Value (basis points)
    uint256 liquidationThreshold;       // Ngưỡng thanh lý (basis points)
    uint256 liquidationBonus;           // Bonus thanh lý (basis points)
    uint256 reserveFactor;              // Reserve factor (basis points)
    bool borrowingEnabled;              // Cho phép borrow
    bool stableBorrowRateEnabled;       // Cho phép stable rate borrow
    uint256 optimalUsageRatio;          // Tỷ lệ sử dụng tối ưu (ray)
    uint256 baseVariableBorrowRate;     // Base variable borrow rate (ray)
    uint256 variableRateSlope1;         // Variable rate slope 1 (ray)
    uint256 variableRateSlope2;         // Variable rate slope 2 (ray)
    uint256 stableRateSlope1;           // Stable rate slope 1 (ray)
    uint256 stableRateSlope2;           // Stable rate slope 2 (ray)
}
```

## 🗺️ Mapping với Aave V3 Structs

### 1. Basic Token Information

#### `name`, `symbol`, `decimals`

- **Aave Struct**: `ConfiguratorInputTypes.InitReserveInput`
- **Mapping**:
  ```solidity
  ConfiguratorInputTypes.InitReserveInput({
      aTokenName: string.concat("Aave Sepolia ", config.symbol),
      aTokenSymbol: string.concat("aSep", config.symbol),
      underlyingAssetDecimals: config.decimals,
      // ...
  })
  ```
- **Ý nghĩa**: Thông tin cơ bản của token để tạo aToken, variableDebtToken, stableDebtToken

### 2. Risk Parameters (Collateral Configuration)

#### `ltv` (Loan to Value)

- **Aave Struct**: `DataTypes.ReserveConfigurationMap` (bits 0-15)
- **Function**: `ReserveConfiguration.setLtv()`
- **Ý nghĩa**:
  - Tỷ lệ tối đa có thể vay dựa trên giá trị collateral
  - **8000 = 80%**: Với $100 collateral có thể vay tối đa $80
  - **Công thức**: `borrowableAmount = collateralValue * ltv / 10000`

#### `liquidationThreshold` (Ngưỡng thanh lý)

- **Aave Struct**: `DataTypes.ReserveConfigurationMap` (bits 16-31)
- **Function**: `ReserveConfiguration.setLiquidationThreshold()`
- **Ý nghĩa**:
  - Ngưỡng Health Factor để trigger thanh lý
  - **8250 = 82.5%**: HF = collateralValue \* 0.825 / debtValue
  - **Luôn >= LTV** để tránh thanh lý ngay lập tức

#### `liquidationBonus` (Bonus thanh lý)

- **Aave Struct**: `DataTypes.ReserveConfigurationMap` (bits 32-47)
- **Function**: `ReserveConfiguration.setLiquidationBonus()`
- **Ý nghĩa**:
  - Discount cho liquidator khi mua collateral
  - **10500 = 105%**: Liquidator trả 95% giá market để mua collateral
  - **Công thức**: `liquidatorPays = collateralValue / (liquidationBonus / 10000)`

### 3. Protocol Revenue

#### `reserveFactor` (Reserve Factor)

- **Aave Struct**: `DataTypes.ReserveConfigurationMap` (bits 64-79)
- **Function**: `ReserveConfiguration.setReserveFactor()`
- **Ý nghĩa**:
  - Phần trăm lợi nhuận từ borrowing fee đi vào treasury
  - **1000 = 10%**: 10% interest payments đi vào protocol treasury
  - **Công thức**: `treasuryIncome = borrowInterest * reserveFactor / 10000`

### 4. Borrowing Configuration

#### `borrowingEnabled`

- **Aave Struct**: `DataTypes.ReserveConfigurationMap` (bit 58)
- **Function**: `PoolConfigurator.setReserveBorrowing()`
- **Ý nghĩa**: Cho phép users borrow token này

#### `stableBorrowRateEnabled`

- **Aave Struct**: `DataTypes.ReserveConfigurationMap` (bit 59)
- **Function**: `PoolConfigurator.setReserveStableRateBorrowing()`
- **Ý nghĩa**: Cho phép stable rate borrowing (fixed interest rate)

### 5. Interest Rate Strategy Parameters

#### `optimalUsageRatio`

- **Aave Struct**: `DefaultReserveInterestRateStrategy.OPTIMAL_USAGE_RATIO`
- **Ý nghĩa**:
  - Tỷ lệ utilization tối ưu của pool
  - **0.8e27 = 80%**: Khi 80% liquidity được borrow
  - **Dưới ngưỡng này**: Interest rate tăng từ từ (slope1)
  - **Trên ngưỡng này**: Interest rate tăng nhanh (slope2)

#### `baseVariableBorrowRate`

- **Aave Struct**: `DefaultReserveInterestRateStrategy._baseVariableBorrowRate`
- **Ý nghĩa**:
  - Lãi suất cơ bản khi utilization = 0%
  - **0 = 0%**: Không có lãi suất cơ bản

#### `variableRateSlope1` & `variableRateSlope2`

- **Aave Struct**: `DefaultReserveInterestRateStrategy._variableRateSlope1/2`
- **Ý nghĩa**:
  - **Slope1**: Độ dốc lãi suất từ 0% đến optimal usage ratio
  - **Slope2**: Độ dốc lãi suất từ optimal đến 100% utilization
  - **Ví dụ**: 0.038e27 = 3.8% tăng thêm khi đạt optimal ratio

#### `stableRateSlope1` & `stableRateSlope2`

- **Aave Struct**: `DefaultReserveInterestRateStrategy._stableRateSlope1/2`
- **Ý nghĩa**: Tương tự variable rate nhưng cho stable borrowing

## 📊 Ví dụ Thực tế: WETH Configuration

```solidity
TokenConfig({
    name: "Wrapped Ether",
    symbol: "WETH",
    decimals: 18,
    initialPrice: 2000_00000000,        // $2000 (8 decimals)
    ltv: 8000,                          // 80% - Có thể vay 80% giá trị WETH
    liquidationThreshold: 8250,         // 82.5% - Thanh lý khi HF < 1
    liquidationBonus: 10500,            // 105% - Liquidator được 5% discount
    reserveFactor: 1000,                // 10% - Protocol lấy 10% interest
    borrowingEnabled: true,             // Cho phép borrow WETH
    stableBorrowRateEnabled: false,     // Không cho stable rate borrow
    optimalUsageRatio: 0.8e27,          // 80% utilization tối ưu
    baseVariableBorrowRate: 0,          // 0% base rate
    variableRateSlope1: 0.038e27,       // 3.8% slope trước optimal
    variableRateSlope2: 0.8e27,         // 80% slope sau optimal
    stableRateSlope1: 0.05e27,          // 5% stable slope trước optimal
    stableRateSlope2: 0.8e27            // 80% stable slope sau optimal
})
```

### Kịch bản sử dụng:

1. **User deposit 1 WETH ($2000)**:

   - Nhận aWETH token
   - Có thể borrow tối đa: `$2000 * 80% = $1600`

2. **User borrow $1500 USDC**:

   - Health Factor = `($2000 * 82.5%) / $1500 = 1.1`
   - Safe vì HF > 1

3. **WETH price giảm xuống $1700**:

   - Health Factor = `($1700 * 82.5%) / $1500 = 0.935`
   - HF < 1 → Có thể bị thanh lý

4. **Liquidation occurs**:
   - Liquidator trả: `$1500 / 1.05 = $1428.57`
   - Liquidator nhận WETH trị giá: `$1500`
   - Profit: `$1500 - $1428.57 = $71.43`

## 📈 Interest Rate Model

### Formula tính lãi suất:

```typescript
if (utilizationRatio <= optimalUsageRatio) {
  variableRate =
    baseVariableBorrowRate +
    (variableRateSlope1 * utilizationRatio) / optimalUsageRatio;
} else {
  excessUtilization =
    (utilizationRatio - optimalUsageRatio) / (1 - optimalUsageRatio);
  variableRate =
    baseVariableBorrowRate +
    variableRateSlope1 +
    variableRateSlope2 * excessUtilization;
}
```

### Ví dụ với WETH:

- **Utilization 40%**: Rate = 0% + (3.8% \* 40% / 80%) = 1.9%
- **Utilization 80%**: Rate = 0% + 3.8% = 3.8%
- **Utilization 90%**: Rate = 0% + 3.8% + (80% \* 10% / 20%) = 43.8%

## 🎯 Asset-Specific Strategies

### Stablecoins (USDC, DAI, USDT, LUSD)

- **High LTV**: 86-87% (ít volatility)
- **High Optimal Usage**: 90% (stable demand)
- **Low Slopes**: Conservative interest rate increases

### ETH Assets (WETH, wstETH, cbETH, rETH)

- **Medium LTV**: 67-80% (moderate volatility)
- **Medium Optimal Usage**: 45-80%
- **Moderate Slopes**: Balanced approach

### Volatile Assets (WBTC, LINK, AAVE, CRV)

- **Low LTV**: 55-70% (high volatility)
- **Low Optimal Usage**: 45%
- **High Slopes**: Aggressive rate increases to manage risk

## 🔄 Runtime Updates

### Các parameters có thể update:

```solidity
// Risk parameters (via PoolConfigurator)
configurator.configureReserveAsCollateral(asset, newLtv, newThreshold, newBonus);
configurator.setReserveFactor(asset, newReserveFactor);
configurator.setReserveBorrowing(asset, newBorrowingEnabled);

// Interest rate strategy (via new deployment)
configurator.setReserveInterestRateStrategyAddress(asset, newStrategy);
```

### Oracle prices (via ChainlinkMockAggregator):

```solidity
// Update price affects Health Factor calculations
oracle.updateAnswer(newPrice);
```

## 🎯 Conclusion

TokenConfig parameters map trực tiếp đến Aave V3 core structs và functions:

1. **Basic Info** → `ConfiguratorInputTypes.InitReserveInput`
2. **Risk Parameters** → `DataTypes.ReserveConfigurationMap` bits
3. **Interest Rates** → `DefaultReserveInterestRateStrategy` constructor
4. **Runtime Config** → `PoolConfigurator` functions

Mỗi parameter được thiết kế để cân bằng giữa **risk management**, **capital efficiency**, và **protocol revenue**.
