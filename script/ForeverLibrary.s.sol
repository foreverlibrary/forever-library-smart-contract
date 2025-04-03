// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/ForeverLibrary.sol";

contract ForeverLibraryScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ForeverLibrary foreverLibrary = new ForeverLibrary();

        vm.stopBroadcast();
    }
}
