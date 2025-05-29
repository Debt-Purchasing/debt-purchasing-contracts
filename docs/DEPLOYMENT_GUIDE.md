# Custom Aave V3 Deployment Guide for Sepolia

## Overview

This guide explains how to deploy a custom Aave V3 infrastructure on Sepolia to solve the **static oracle problem** and enable dynamic Health Factor testing for the debt purchasing protocol.

## Problem Solved

**Original Issue**: Sepolia's official Aave V3 deployment uses static mock oracles that never update prices, making it impossible to test:

- Dynamic Health Factor changes
- Order execution based on HF thresholds
- Liquidation scenarios
- Real-time price-based features

**Solution**: Deploy our own simplified Aave V3 infrastructure with updateable oracles.

## Architecture

### Simplified Aave V3 Components

```
Custom Aave V3 Sepolia Deployment
├── PoolAddressesProvider (core registry)
├── ACLManager (access control)
├── PriceOracle (updateable prices)
└── Test Tokens (WETH, USDC, DAI, WBTC)
```

### Key Benefits

1. **Updateable Oracles**: Can change prices on-demand for testing
2. **Full Control**: Complete control over all parameters
3. **Simplified**: Only essential components for debt purchasing testing
4. **Compatible**: Works with existing AaveRouter contracts

## Deployment Steps

### 1. Prerequisites

Ensure you have the following in your `.env` file:

```bash
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_project_id
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### 2. Deploy Simple Aave V3

```bash
# Make script executable
chmod +x deploy_simple_aave_v3_sepolia.sh

# Deploy
./deploy_simple_aave_v3_sepolia.sh
```

### 3. Expected Output

The deployment will create:

```
=== SIMPLE AAVE V3 DEPLOYMENT SUMMARY ===
PoolAddressesProvider: 0x...
ACL Manager: 0x...
Price Oracle: 0x...

=== TEST TOKENS ===
WETH: 0x...
USDC: 0x...
DAI: 0x...
WBTC: 0x...
```

### 4. Update Oracle Script

Copy the deployed addresses and update `script/deploy-aavev3-sepolia/UpdateOracle.sol`:

```solidity
// Oracle addresses (update after deployment)
address constant PRICE_ORACLE = 0x...; // Your deployed oracle
address constant WETH = 0x...; // Your deployed WETH
address constant USDC = 0x...; // Your deployed USDC
address constant DAI = 0x...; // Your deployed DAI
address constant WBTC = 0x...; // Your deployed WBTC
```

## Testing Oracle Updates

### Basic Price Update

```bash
forge script script/deploy-aavev3-sepolia/UpdateOracle.sol:UpdateOracle \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast
```

### Simulate Market Scenarios

```bash
# Bear market (prices drop)
forge script script/deploy-aavev3-sepolia/UpdateOracle.sol:UpdateOracle \
    --sig "simulateBearMarket()" \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast

# Bull market (prices rise)
forge script script/deploy-aavev3-sepolia/UpdateOracle.sol:UpdateOracle \
    --sig "simulateBullMarket()" \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast

# Reset to initial prices
forge script script/deploy-aavev3-sepolia/UpdateOracle.sol:UpdateOracle \
    --sig "resetToInitialPrices()" \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast
```

## Integration with Debt Purchasing System

### 1. Update AaveRouter Deployment

Update your AaveRouter deployment script to use the custom PoolAddressesProvider:

```solidity
// In DeployAaveRouter.s.sol
if (chainId == 11155111) {
    aavePoolAddressesProvider = 0x...; // Your custom PoolAddressesProvider
}
```

### 2. Update Subgraph Configuration

Update `subgraph/subgraph.yaml` with your custom contract addresses:

```yaml
dataSources:
  - kind: ethereum/contract
    name: AaveOracle
    network: sepolia
    source:
      address: "0x..." # Your custom PriceOracle
      abi: PriceOracle
      startBlock: your_deployment_block
```

### 3. Test Complete Flow

1. **Deploy AaveRouter** with custom PoolAddressesProvider
2. **Create debt positions** using test tokens
3. **Update oracle prices** to trigger HF changes
4. **Execute orders** based on HF thresholds
5. **Monitor subgraph** for real-time updates

## Testing Scenarios

### Scenario 1: Liquidation Risk Testing

```bash
# 1. Create position with WBTC collateral, USDC debt
# 2. Drop WBTC price by 30%
forge script script/deploy-aavev3-sepolia/UpdateOracle.sol:UpdateOracle \
    --sig "updateWBTCPrice(int256)" 42000_00000000 \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast

# 3. Check Health Factor drops below threshold
# 4. Execute sell order to avoid liquidation
```

### Scenario 2: Order Sorting by HF

```bash
# 1. Create multiple positions
# 2. Gradually drop prices
# 3. Watch orders sort by HF proximity to trigger
# 4. Execute orders in priority order
```

### Scenario 3: Dynamic UI Testing

```bash
# 1. Set up real-time price updates
# 2. Watch UI update Health Factors live
# 3. Test order creation/execution flows
# 4. Verify subgraph data accuracy
```

## Advantages Over Official Aave V3

| Feature           | Official Aave V3 Sepolia      | Custom Deployment        |
| ----------------- | ----------------------------- | ------------------------ |
| Oracle Updates    | ❌ Static (never change)      | ✅ Dynamic (on-demand)   |
| Price Control     | ❌ No control                 | ✅ Full control          |
| Testing Scenarios | ❌ Limited                    | ✅ Unlimited             |
| HF Testing        | ❌ Impossible                 | ✅ Complete              |
| Order Execution   | ❌ Fails due to static prices | ✅ Works with real logic |

## Troubleshooting

### Common Issues

1. **Deployment Fails**

   - Check gas limits and RPC URL
   - Ensure sufficient ETH in deployer account

2. **Oracle Updates Fail**

   - Verify contract addresses in UpdateOracle.sol
   - Check deployer has oracle update permissions

3. **AaveRouter Integration Issues**
   - Ensure PoolAddressesProvider address is correct
   - Verify oracle is properly set in provider

### Verification

```bash
# Verify oracle price
cast call $PRICE_ORACLE "getAssetPrice(address)" $WBTC --rpc-url $SEPOLIA_RPC_URL

# Verify PoolAddressesProvider setup
cast call $POOL_ADDRESSES_PROVIDER "getPriceOracle()" --rpc-url $SEPOLIA_RPC_URL
```

## Next Steps

1. **Deploy the system** using the provided scripts
2. **Test oracle updates** with various scenarios
3. **Integrate with AaveRouter** and debt purchasing contracts
4. **Update subgraph** configuration
5. **Build UI** with real-time Health Factor monitoring
6. **Scale to production** when ready

This custom deployment provides the foundation for comprehensive testing of the debt purchasing protocol with dynamic oracle prices, solving the fundamental limitation of static testnet oracles.
