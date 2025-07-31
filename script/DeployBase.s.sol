// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BaseTip} from "../src/BaseTip.sol";

contract DeployBaseTipOnBase is Script {
    function run() external returns (BaseTip) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying to Base Sepolia Testnet");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        BaseTip baseTip = new BaseTip();
        
        console.log("=== BaseTip Deployment Successful ===");
        console.log("Contract address:", address(baseTip));
        console.log("Contract owner:", baseTip.owner());
        console.log("Minimum tip amount:", baseTip.MINIMUM_TIP());
        console.log("Platform fee:", baseTip.platformFee(), "basis points (1% = 100 bp)");
        
        // Verify deployment
        require(baseTip.owner() == deployer, "Owner mismatch");
        require(baseTip.MINIMUM_TIP() == 0.001 ether, "Minimum tip mismatch");
        
        console.log("=== Deployment Verified ===");
        console.log("Save this address to your .env file:");
        console.log("BASETIP_CONTRACT_ADDRESS=", address(baseTip));
        
        vm.stopBroadcast();
        
        return baseTip;
    }
}