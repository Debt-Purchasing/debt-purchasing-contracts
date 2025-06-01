# Comprehensive Aave V3 Deployment Guide

## 📋 Overview

This guide explains how to deploy a complete Aave V3 system on Sepolia with:

- ✅ 12 Production tokens (WETH, wstETH, WBTC, USDC, DAI, LINK, AAVE, cbETH, USDT, rETH, LUSD, CRV)
- ✅ Chainlink-compatible mock oracles with proper events for subgraph
- ✅ Production-like reserve configurations and risk parameters
- ✅ Complete Aave V3 infrastructure (Pool, Configurator, ACL, etc.)
- ✅ Multiple interest rate strategies based on asset type

## 🚀 Quick Deployment

### 1. Prerequisites

```bash
# Required environment variables
export PRIVATE_KEY="your_private_key_here"
export SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/your_key"

# Make deployment script executable
chmod +x deploy_comprehensive_aave_v3_sepolia.sh
```

### 2. Deploy Everything

```bash
# Single command to deploy complete system
./deploy_comprehensive_aave_v3_sepolia.sh
```

## 📊 Token Configuration

### Production Tokens Deployed

| Token           | Symbol | Decimals | Initial Price | LTV | Liquidation Threshold | Borrowing |
| --------------- | ------ | -------- | ------------- | --- | --------------------- | --------- |
| Wrapped Ether   | WETH   | 18       | $2,000        | 80% | 82.5%                 | ✅        |
| Wrapped stETH   | wstETH | 18       | $2,200        | 75% | 80%                   | ✅        |
| Wrapped BTC     | WBTC   | 8        | $60,000       | 70% | 75%                   | ✅        |
| USD Coin        | USDC   | 6        | $1            | 87% | 89%                   | ✅        |
| Dai Stablecoin  | DAI    | 18       | $1            | 86% | 88%                   | ✅        |
| Chainlink       | LINK   | 18       | $15           | 70% | 75%                   | ✅        |
| Aave Token      | AAVE   | 18       | $80           | 66% | 73%                   | ❌        |
| Coinbase stETH  | cbETH  | 18       | $2,100        | 74% | 77%                   | ✅        |
| Tether USD      | USDT   | 6        | $1            | 86% | 88%                   | ✅        |
| Rocket Pool ETH | rETH   | 18       | $2,050        | 67% | 74%                   | ✅        |
| LUSD Stablecoin | LUSD   | 18       | $1            | 80% | 85%                   | ✅        |
| Curve DAO       | CRV    | 18       | $0.5          | 55% | 61%                   | ✅        |

### Interest Rate Strategies

- **Stablecoin Strategy**: USDC, DAI, USDT, LUSD (90% optimal usage)
- **ETH Strategy**: WETH, wstETH, cbETH, rETH (80% optimal usage)
- **BTC Strategy**: WBTC (45% optimal usage)
- **Altcoin Strategy**: LINK, AAVE, CRV (45% optimal usage)

## 🔧 Deployment Components

### Core Infrastructure

1. **PoolAddressesProvider**: Central registry for all Aave contracts
2. **Pool**: Main lending pool contract (proxy)
3. **PoolConfigurator**: Configuration management (proxy)
4. **ACLManager**: Access control and permissions
5. **AaveOracle**: Aggregates all Chainlink price feeds

### Chainlink Mock Oracles

- Compatible with Chainlink interface
- Emit `AnswerUpdated` and `NewRound` events
- Perfect for subgraph integration
- Updateable prices for dynamic testing

### Token Infrastructure

- **ATokens**: Interest-bearing tokens (aSepWETH, aSepUSDC, etc.)
- **Variable Debt Tokens**: Variable rate debt tracking
- **Stable Debt Tokens**: Stable rate debt tracking

## 📈 Testing Market Scenarios

### Update Oracle Prices

After deployment, update the oracle addresses in `UpdateComprehensiveOracles.sol`:

```solidity
OracleAddresses memory oracles = OracleAddresses({
    weth: 0xYOUR_WETH_ORACLE_ADDRESS,
    wstETH: 0xYOUR_WSTETH_ORACLE_ADDRESS,
    // ... update all addresses
});
```

### Available Market Scenarios

```bash
# Bull Market (+30-50% gains)
forge script script/for-testing/UpdateComprehensiveOracles.sol:UpdateComprehensiveOracles \
    --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast

# Bear Market (-20-40% decline)
# Edit scenario = "bear" in UpdateComprehensiveOracles.sol

# Market Crash (-50-70% decline)
# Edit scenario = "crash" in UpdateComprehensiveOracles.sol

# Recovery Market (+10% modest gains)
# Edit scenario = "recovery" in UpdateComprehensiveOracles.sol

# Custom Prices
# Edit scenario = "custom" and modify prices in UpdateComprehensiveOracles.sol
```

## 🎯 Debt Purchasing Integration

### Update AaveRouter Configuration

After deployment, update your `AaveRouter.sol` to use the new PoolAddressesProvider:

```solidity
// In your AaveRouter deployment script
address poolAddressesProvider = 0xYOUR_DEPLOYED_POOL_ADDRESSES_PROVIDER;
```

### Health Factor Testing Flow

1. **Deploy User Position**: Use AaveRouter to create debt positions
2. **Change Oracle Prices**: Use UpdateComprehensiveOracles script
3. **Monitor Health Factor**: Check real-time HF changes
4. **Execute Purchase Orders**: Test debt purchasing when HF drops
5. **Verify Liquidation**: Test liquidation scenarios

## 📊 Subgraph Configuration

### Update Subgraph Addresses

Update your `subgraph.yaml` with new contract addresses:

```yaml
dataSources:
  - kind: ethereum/contract
    name: AaveOracle
    network: sepolia
    source:
      address: "YOUR_AAVE_ORACLE_ADDRESS"
      abi: AaveOracle
      startBlock: YOUR_DEPLOYMENT_BLOCK
    mapping:
      # Oracle price updates

  - kind: ethereum/contract
    name: ChainlinkAggregators
    network: sepolia
    source:
      address: "YOUR_WETH_ORACLE_ADDRESS"
      abi: ChainlinkMockAggregator
      startBlock: YOUR_DEPLOYMENT_BLOCK
    mapping:
      # Individual oracle events
```

### Key Events to Index

- `AnswerUpdated(int256 current, uint256 roundId, uint256 updatedAt)`
- `NewRound(uint256 roundId, address startedBy, uint256 startedAt)`
- Pool events for supply/borrow/liquidation

## 🧪 Testing Checklist

### Basic Functionality

- [ ] All 12 tokens deployed successfully
- [ ] All Chainlink oracles deployed with events
- [ ] AaveOracle aggregating all price feeds
- [ ] Pool and PoolConfigurator proxies working
- [ ] ACL permissions set correctly

### Oracle Testing

- [ ] Oracle prices update successfully
- [ ] Events emitted properly
- [ ] Subgraph captures price changes
- [ ] Health Factor calculations updated

### Debt Purchasing Testing

- [ ] AaveRouter connects to new Pool
- [ ] User positions created successfully
- [ ] Health Factor changes with price updates
- [ ] Purchase orders execute correctly
- [ ] Liquidation scenarios work

### Integration Testing

- [ ] Subgraph indexes all events
- [ ] UI displays dynamic Health Factors
- [ ] Real-time price updates reflected
- [ ] Complete debt purchasing flow works

## 🛠️ Troubleshooting

### Common Issues

#### 1. Deployment Failures

```bash
# Check gas limit
--gas-limit 30000000

# Check RPC endpoint
echo $SEPOLIA_RPC_URL

# Verify private key
cast wallet address --private-key $PRIVATE_KEY
```

#### 2. Oracle Update Failures

- Ensure oracle addresses are correct in UpdateComprehensiveOracles.sol
- Check transaction gas limit
- Verify network connectivity

#### 3. Reserve Configuration Issues

- Check ACL permissions (Pool Admin, Risk Admin)
- Verify interest rate strategy addresses
- Ensure token decimals match configuration

#### 4. Subgraph Issues

- Verify contract addresses in subgraph.yaml
- Check event signatures match deployed contracts
- Ensure startBlock is correct

## 📋 Post-Deployment Steps

1. **Save All Addresses**: Record all deployed contract addresses
2. **Update Environment**: Set environment variables for addresses
3. **Configure Subgraph**: Update subgraph with new addresses
4. **Test Oracle Updates**: Verify price update functionality
5. **Integration Testing**: Test complete debt purchasing flow
6. **Documentation**: Update project documentation with new addresses

## 🎉 Success Criteria

Your deployment is successful when:

- ✅ All 12 production tokens are deployed and configured
- ✅ Chainlink oracles emit proper events for subgraph
- ✅ Health Factor calculations work with real oracle prices
- ✅ Debt purchasing orders execute based on dynamic HF
- ✅ Complete testing environment matches production behavior

## 📞 Support

If you encounter issues:

1. Check this troubleshooting guide
2. Verify all prerequisites are met
3. Review deployment logs for specific errors
4. Test with smaller deployments first

---

**🎯 Result**: A production-ready Aave V3 deployment on Sepolia that enables comprehensive debt purchasing testing with dynamic Health Factor simulation and real oracle price updates.
