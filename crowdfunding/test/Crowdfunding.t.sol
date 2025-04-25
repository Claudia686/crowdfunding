// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";

contract CrowdfundingTest is Test {
    Crowdfunding crowdfunding;
    address public USER = makeAddr("user");

    function setUp() public {
        uint256 goal = 10e18;
        uint256 deadline = 10 days;
        crowdfunding = new Crowdfunding(goal, deadline);
    }

    function testZeroContribution() public {
        vm.prank(USER);
        vm.expectRevert(Crowdfunding.NoEthSent.selector);
        crowdfunding.contribute{value: 0}();
    }

    function testDeadlineNotPassed() public {
        vm.deal(USER, 2e18);
        vm.warp(block.timestamp + 11 * 24 * 60 * 60);
        vm.prank(USER);
        vm.expectRevert(Crowdfunding.DeadlinePassed.selector);
        crowdfunding.contribute{value: 1e18}();
    }

    function testEventForContribution() public {
        vm.deal(USER, 2e18); 
        vm.prank(USER); 
        vm.expectEmit(true, true, false, true);
        emit Crowdfunding.Contributed(USER, 2e18);
        crowdfunding.contribute{value: 2e18}();
    }

    function testMultipleContributions() public {
        vm.deal(USER, 2e18);
        vm.prank(USER);
        crowdfunding.contribute{value: 2e18}();
        vm.deal(USER, 3e18);
        vm.prank(USER);
        crowdfunding.contribute{value: 3e18}();
        assertEq(crowdfunding.contributions(USER), 5e18);
        assertEq(crowdfunding.totalContributions(), 5e18);
    }
}
