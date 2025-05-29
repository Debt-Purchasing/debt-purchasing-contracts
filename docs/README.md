# 📚 Documentation

This directory contains deployment guides and documentation for the debt purchasing contracts project.

## 📋 Available Guides

### [🏗️ Local Deployment Guide](LOCAL_DEPLOYMENT_GUIDE.md)

Comprehensive guide for deploying production-accurate Aave V3 locally with:

- ✅ EIP-1559 compatible Ganache setup
- ✅ All 12 mainnet tokens with real parameters
- ✅ Dynamic oracle price testing utilities
- ✅ Interactive Aave testing scripts
- ✅ Health Factor scenario testing

## 🎯 Quick Start

1. **Start Environment**: `./ganache-setup.sh`
2. **Deploy Aave V3**: `./deploy_production_aave_v3_local.sh`
3. **Test Scenarios**: `./scripts-utils/update_prices.sh`
4. **Interact**: `./scripts-utils/interact_with_aave.sh`

## 📁 Related Files

- `ganache-setup.sh` - EIP-1559 compatible local blockchain
- `deploy_production_aave_v3_local.sh` - Local production deployment
- `deploy_production_aave_v3_sepolia.sh` - Sepolia testnet deployment
- `scripts-utils/` - Testing and interaction utilities
- `script/utilities/` - Solidity utility contracts

---

**Ready for production-level testing! 🚀**
