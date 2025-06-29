# 📚 Documentation

This directory contains deployment guides and documentation for the debt purchasing contracts project.

## 📋 Available Guides

### [🏗️ Local Deployment Guide](LOCAL_DEPLOYMENT_GUIDE.md)

Comprehensive guide for deploying production-accurate Aave V3 locally with:

- ✅ EIP-1559 compatible Anvil setup
- ✅ All 12 mainnet tokens with real parameters
- ✅ Dynamic oracle price testing utilities
- ✅ Interactive Aave testing scripts
- ✅ Health Factor scenario testing

## 🎯 Quick Start

1. **Start Environment**: `./scripts-utils/local/start_anvil.sh`
2. **Deploy Aave V3**: `./scripts-utils/local/deploy_aave_v3_local.sh`
3. **Seed lending and borrowing Aave V3**: `./scripts-utils/local/seed_lending_and_borrowing.sh`
4. **Test Scenarios**: `./scripts-utils/local/update_prices.sh`

---

**Ready for production-level testing! 🚀**
