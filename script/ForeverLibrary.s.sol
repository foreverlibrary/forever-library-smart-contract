// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/ForeverLibrary.sol";

contract DeployForeverLibrary is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ForeverLibrary foreverLibrary = new ForeverLibrary();

        vm.stopBroadcast();

        console2.log("ForeverLibrary deployed at:", address(foreverLibrary));
    }
}
