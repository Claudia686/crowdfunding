// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";

contract DeployCrowdfunding is Script {
    address public USER = makeAddr("user");
    address public OWNER = makeAddr("owner");

    function run() external returns (Crowdfunding) {
        uint256 goal = 10e18;
        uint256 deadline = 10 days;

        vm.startBroadcast();
        Crowdfunding crowdfunding = new Crowdfunding(goal, deadline);
        vm.stopBroadcast();
        return crowdfunding;
    }
}
