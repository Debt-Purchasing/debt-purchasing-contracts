// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AaveRouter} from "../src/AaveRouter.sol";
import {AaveDebt} from "../src/AaveDebt.sol";

contract DeployAaveRouter is Script {
    function run() external returns (AaveRouter) {
        uint256 chainId = block.chainid;
        address aavePoolAddressesProvider;

        if (chainId == 11155111) {
            aavePoolAddressesProvider = vm.envAddress(
                "POOL_ADDRESSES_PROVIDER_SEPOLIA"
            );
        } else if (chainId == 1) {
            aavePoolAddressesProvider = vm.envAddress(
                "POOL_ADDRESSES_PROVIDER_MAINNET"
            );
        } else {
            revert();
        }

        vm.startBroadcast();

        AaveDebt aaveDebt = new AaveDebt();

        AaveRouter aaveRouter = new AaveRouter(
            address(aaveDebt),
            aavePoolAddressesProvider
        );
        vm.stopBroadcast();

        console.log("AAVE ROUTER ADDRESS: ", address(aaveRouter));

        return aaveRouter;
    }
}
