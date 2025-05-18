// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "forge-std/Script.sol";
// import "../src/DebtVault.sol";
// // Uncomment these when the contracts are implemented
// // import "../src/DebtSaleManager.sol";
// // import "../src/DebtOwnershipRegistry.sol";

// /**
//  * @title DeployScript
//  * @dev Script for deploying all contracts
//  */
// contract DeployScript is Script {
//     // Sepolia testnet - Aave V3
//     address constant SEPOLIA_POOL_ADDRESSES_PROVIDER = 0xD64dDe119f11C88850FD596BE11CE398CC5893e6;

//     function run() external {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

//         vm.startBroadcast(deployerPrivateKey);

//         // Deploy DebtVault
//         DebtVault debtVault = new DebtVault(SEPOLIA_POOL_ADDRESSES_PROVIDER);
//         console.log("DebtVault deployed at:", address(debtVault));

//         /*
//         // Uncomment these when the contracts are implemented
//         // Deploy DebtOwnershipRegistry
//         DebtOwnershipRegistry debtOwnershipRegistry = new DebtOwnershipRegistry();
//         console.log("DebtOwnershipRegistry deployed at:", address(debtOwnershipRegistry));

//         // Deploy DebtSaleManager
//         DebtSaleManager debtSaleManager = new DebtSaleManager(
//             address(debtVault),
//             address(debtOwnershipRegistry)
//         );
//         console.log("DebtSaleManager deployed at:", address(debtSaleManager));

//         // Set up permissions
//         debtOwnershipRegistry.transferOwnership(address(debtSaleManager));
//         */

//         vm.stopBroadcast();
//     }
// }
