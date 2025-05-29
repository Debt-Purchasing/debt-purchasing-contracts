#!/bin/bash

set -a
source .env
set +a

if [[ $1 == 11155111 ]] 
then 
    forge script script/DeployAaveRouter.s.sol:DeployAaveRouter --rpc-url $RPC_URL_TESTNET --ledger --sender $DEPLOYER_ADDRESS_TESTNET --broadcast
elif [[ $1 == 1 ]] 
then
    forge script script/DeployAaveRouter.s.sol:DeployAaveRouter --rpc-url $RPC_URL_MAINNET --ledger --sender $DEPLOYER_ADDRESS_MAINNET --broadcast
fi