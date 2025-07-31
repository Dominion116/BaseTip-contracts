// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BaseTip} from "../src/BaseTip.sol";

contract DeployBaseTip is Script {
    function run() external returns (BaseTip) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        BaseTip baseTip = new BaseTip();
        
        console.log("BaseTip deployed to:", address(baseTip));
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Minimum tip:", baseTip.MINIMUM_TIP());
        
        vm.stopBroadcast();
        
        return baseTip;
    }
}