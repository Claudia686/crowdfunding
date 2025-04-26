// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";

contract CrowdfundingTest is Test {
    Crowdfunding crowdfunding;
    address public USER = makeAddr("user");
    address public OWNER = makeAddr("owner");

    function setUp() public {
        uint256 goal = 10e18;
        uint256 deadline = 10 days;
        vm.prank(OWNER);
        crowdfunding = new Crowdfunding(goal, deadline);
    }

    // --------------------------
    // Test contribute success
    // --------------------------

    // Emit event after contribution
    function testEventForContribution() public {
        vm.deal(USER, 2e18);
        vm.prank(USER);
        vm.expectEmit(true, true, false, true);
        emit Crowdfunding.Contributed(USER, 2e18);
        crowdfunding.contribute{value: 2e18}();
    }

    // Multiple contributions from the same user
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

    // --------------------------
    // Test contribute failure
    // --------------------------

    // Revert with zero contribution
    function testRevertZeroContribution() public {
        vm.prank(USER);
        vm.expectRevert(Crowdfunding.NoEthSent.selector);
        crowdfunding.contribute{value: 0}();
    }

    // Revert if user tries to contribute after deadline
    function testRevertDeadlineNotPassed() public {
        vm.deal(USER, 2e18);
        vm.warp(block.timestamp + 11 * 24 * 60 * 60);
        vm.prank(USER);
        vm.expectRevert(Crowdfunding.DeadlinePassed.selector);
        crowdfunding.contribute{value: 1e18}();
    }

    // --------------------------
    // Test withdraw success
    // --------------------------

    // Owner withdraws funds after deadline and goal met
    function testWithdrawSuccess() public {
        vm.deal(USER, 11e18);
        vm.prank(USER);
        crowdfunding.contribute{value: 11e18}();
        vm.warp(block.timestamp + 11 * 24 * 60 * 60);
        vm.prank(OWNER);
        crowdfunding.withdraw();
    }

    // Emit event after successful withdraw
    function testEventAfterWithdraw() public {
        vm.deal(USER, 11e18);
        vm.prank(USER);
        crowdfunding.contribute{value: 11e18}();
        vm.warp(block.timestamp + 11 * 24 * 60 * 60);
        vm.prank(OWNER);
        vm.expectEmit(true, true, false, true);
        emit Crowdfunding.Withdraw(OWNER, 11e18);
        crowdfunding.withdraw();
    }

    // --------------------------
    // Test withdraw failure
    // --------------------------

    // Revert withdraw before deadline
    function testRevertWithdrawBeforeDeadlineFinished() public {
        vm.deal(USER, 2e18);
        vm.prank(USER);
        crowdfunding.contribute{value: 2e18}();
        vm.warp(block.timestamp * 1 * 24 * 60 * 60);
        vm.prank(OWNER);
        vm.expectRevert(Crowdfunding.DeadlineNotPassed.selector);
        crowdfunding.withdraw();
    }

    // Revert withdraw if goal not met
    function testRevertWithdrawIfGoalNotMet() public {
        vm.deal(USER, 2e18);
        vm.prank(USER);
        crowdfunding.contribute{value: 2e18}();
        vm.warp(block.timestamp + 11 * 24 * 60 * 60);
        vm.prank(OWNER);
        vm.expectRevert(Crowdfunding.GoalNotMet.selector);
        crowdfunding.withdraw();
    }

    // Revert no-owner from withdraw
    function testRevertNonOwnerFromWithdraw() public {
        vm.deal(USER, 20e18);
        vm.startPrank(USER);
        crowdfunding.contribute{value: 20e18}();
        vm.warp(block.timestamp + 11 * 24 * 60 * 60);
        vm.expectRevert(Crowdfunding.NotTheOwner.selector);
        crowdfunding.withdraw();
        vm.stopPrank();
    }

    // Revert if already withdrawn
    function testRevertMultipleWithdrawals() public {
        vm.deal(OWNER, 20e18);
        vm.startPrank(OWNER);
        crowdfunding.contribute{value: 20e18}();
        vm.warp(block.timestamp + 11 * 24 * 60 * 60);
        crowdfunding.withdraw();
        vm.stopPrank();
        vm.prank(OWNER);
        vm.expectRevert(Crowdfunding.NoFundsToWithdraw.selector);
        crowdfunding.withdraw();
    }

    // --------------------------
    // Test refund success
    // --------------------------

    // Refund user if deadline not passed
    function testSuccessRefund() public {
        vm.deal(USER, 1e18);
        vm.prank(USER);
        crowdfunding.contribute{value: 1e18}();
        vm.warp(block.timestamp + 1 * 60);
        vm.prank(USER);
        crowdfunding.refund();
        assertEq(crowdfunding.contributions(USER), 0);
    }

    // Emit refund event
    function testRefundEvent() public {
        vm.deal(USER, 1e18);
        vm.startPrank(USER);
        crowdfunding.contribute{value: 1e18}();
        vm.warp(block.timestamp + 1);
        vm.expectEmit(true, true, false, true);
        emit Crowdfunding.Refunded(USER, 1e18);
        crowdfunding.refund();
        vm.stopPrank();
    }

    // --------------------------
    // Test refund failure
    // --------------------------

    // Revert refund if deadline passed
    function testRevertRefundAfterDeadline() public {
        vm.deal(USER, 1e18);
        vm.startPrank(USER);
        crowdfunding.contribute{value: 1e18}();
        vm.warp(block.timestamp + 20 * 24 * 60 * 60);
        vm.expectRevert(Crowdfunding.DeadlinePassed.selector);
        crowdfunding.refund();
        vm.stopPrank();
    }

    // Revert if user already refunded
    function testRevertIfAlreadyRefunded() public {
        vm.deal(USER, 1e18);
        vm.startPrank(USER);
        crowdfunding.contribute{value: 1e18}();
        vm.warp(block.timestamp + 2);
        crowdfunding.refund();
        vm.expectRevert(Crowdfunding.NothingToRefund.selector);
        crowdfunding.refund();
        vm.stopPrank();
    }

    // --------------------------
    // Test total contributions success
    // --------------------------

    // Check total contributions after a single contribution
    function testTotalContributions() public {
        vm.deal(USER, 1e18);
        vm.startPrank(USER);
        crowdfunding.contribute{value: 1e18}();
        assertEq(crowdfunding.getTotalContributions(), 1e18);
        vm.stopPrank();
    }

   // Check total contributions after multiple contributions
    function testGetMultipleTotalContributions() public {
        vm.deal(USER, 3e18);
        vm.startPrank(USER);
        crowdfunding.contribute{value: 1e18}();
        crowdfunding.contribute{value: 2e18}();
        assertEq(crowdfunding.getTotalContributions(), 3e18);
        vm.stopPrank();
 }
}