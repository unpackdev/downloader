// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ResolutionContract {
    address public owner;
    uint256 public reclaimDate;
    mapping(address => uint256) public deposits;

    constructor() {
        owner = msg.sender;
        reclaimDate = 1704067200; // Timestamp for January 1, 2024
    }

    modifier afterReclaimDate() {
        require(block.timestamp >= reclaimDate, "Withdrawal not allowed yet");
        _;
    }
    
    function withdraw(uint256 amount) external afterReclaimDate {
        require(amount <= deposits[msg.sender], "Insufficient balance");

        deposits[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Fallback function for receiving Ether
    receive() external payable {
        deposits[msg.sender] += msg.value;
    }

    fallback() external payable {
        deposits[msg.sender] += msg.value;
    }

}