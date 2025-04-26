// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title Crowdfunding
 * @author Claudia
 * @notice A simple crowdfunding contract
 */
contract Crowdfunding {
    /**
     * @notice address of the contract owner
     * @notice goal amount to reach
     * @notice deadline in seconds
     * @notice total contributions made
     */
    address public owner;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalContributions;

    /**
     * @notice mapping to store user contributions
     * @notice user address => contribution amount
     */
    mapping(address => uint256) public contributions;

    /**
     * @notice Emits when a user contributes to the crowdfunding campaign
     * @notice Emits when a user is refunded
     * @notice Emits when the owner withdraws funds
     */
    event Contributed(address indexed user, uint256 indexed amount);
    event Refunded(address indexed user, uint256 indexed amount);
    event Withdraw(address indexed owner, uint256 indexed amount);

    /**
     * @dev Thrown when a user tries to contribute with zero value
     * @dev Thrown when non-owner tries to withdraw
     * @dev Thrown when user tries to get a refund after deadline
     * @dev Thrown when woner tries to withdraw before deadline
     * @dev Thrown when user tries to get refund without contribution
     * @dev Thrown when woner tries to withdraw and goal is not met
     * @dev Trown when user tries to get refund after already refunded
     * @dev Thrown if withdraw fails
     * @dev Thrown if no funds to withdraw
     */
    error NoEthSent();
    error NotTheOwner();
    error DeadlinePassed();
    error DeadlineNotPassed();
    error NothingToRefund();
    error GoalNotMet();
    error RefundFailed();
    error WithdrawFailed();
    error NoFundsToWithdraw();

    /**
     * @dev Only owner can withdraw funds
     */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotTheOwner();
        }
        _;
    }

    /**
     * @dev Constructor to set goal and deadline
     * @param _goal The goal amount to reach
     * @param _deadline The deadline in seconds
     */
    constructor(uint256 _goal, uint256 _deadline) {
        goal = _goal;
        deadline = block.timestamp + _deadline;
        owner = msg.sender;
    }

    /**
     * @notice Contribute to the crowdfunding campaign
     * @dev Check if value is not zero
     * @dev Check if deadline not passed
     * @dev Update user contribution
     * @dev Update total contributions
     * @dev Emit `Contributed`event
     */
    function contribute() public payable {
        if (msg.value == 0) {
            revert NoEthSent();
        }
        if (block.timestamp > deadline) {
            revert DeadlinePassed();
        }
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
        emit Contributed(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw funds from the crowdfunding campaign
     * @dev Check if deadline passed
     * @dev Check if goal met to be able to withdraw
     * @dev Check if there are funds in the contract to withdraw
     * @dev Emit `Withdraw` event
     * @dev Withdraw all funds to the owner address
     */
    function withdraw() public onlyOwner {
        if (block.timestamp < deadline) {
            revert DeadlineNotPassed();
        }
        if (totalContributions < goal) {
            revert GoalNotMet();
        }
        uint256 amount = address(this).balance;
        if (amount == 0) {
            revert NoFundsToWithdraw();
        }
        emit Withdraw(owner, amount);
        (bool success,) = owner.call{value: amount}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    /**
     * @notice Refund user if deadline not passed
     * @dev Check if deadline not passed
     * @dev Check if user has contributed
     * @dev Update user contribution to zero
     * @dev Refund user the amount contributed
     * @dev Emit `Refunded` event
     */
    function refund() public {
        if (block.timestamp > deadline) {
            revert DeadlinePassed();
        }
        if (contributions[msg.sender] == 0) {
            revert NothingToRefund();
        }

        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: refundAmount}("");
        if (!success) {
            revert RefundFailed();
        }
        emit Refunded(msg.sender, refundAmount);
    }

    /**
     * @notice Returns total contribution balance
     */
    function getTotalContributions() public view returns (uint256) {
        return contributions[msg.sender];
    }

    /**
     * @notice Returns contract balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
