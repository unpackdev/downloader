// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DenariCoin {
    string public name = "DenariCoin";
    string public symbol = "DNC";
    uint8 public decimals = 18;
    
    // Updated total supply and starting supply
    uint256 public totalSupply = 777000000000000000000000000; // 777,000,000,000,000 DNC
    uint256 public startingSupply = 333000000000000000000000000; // 333,000,000,000,000 DNC
    uint256 public currentSupply = startingSupply;

    // Supply release parameters
    uint256 public monthlyReleaseAmount = 3000000000000; // 3,000,000,000,000 DNC
    uint256 public releaseStartTime;
    uint256 public releaseEndTime;
    uint256 public releaseInterval = 30 days; // Release every month

    // Lockup parameters
    address public lockedAddress = 0xB29e47Ae592E8F5C23EbfdB187755ED4202cb0F9;
    uint256 public lockedAmount = 30000000000000000; // 30,000,000,000,000 DNC
    uint256 public lockupDuration = 7 * 365 days; // 7 years
    uint256 public lockupEndTime;

    // Mapping to track balances
    mapping(address => uint256) public balanceOf;

    constructor() {
        // Allocate 3,000,000,000,000 DNC to the locked address immediately
        balanceOf[lockedAddress] = 3000000000000000;
        
        // Allocate the remaining starting supply to the contract deployer
        balanceOf[msg.sender] = startingSupply;
        
        releaseStartTime = block.timestamp; // Start releases immediately
        releaseEndTime = releaseStartTime + ((totalSupply - startingSupply) / monthlyReleaseAmount) * releaseInterval; // End releases when total supply reaches 777,000,000,000,000 DNC
        lockupEndTime = block.timestamp + lockupDuration; // Lockup ends after 7 years
    }

    function transfer(address to, uint256 amount) public {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        // Check lockup period for locked address
        if (msg.sender == lockedAddress) {
            require(block.timestamp >= lockupEndTime || balanceOf[msg.sender] - amount >= lockedAmount, "Funds are locked");
        }

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }

    // Implement the supply release mechanism with halving
    function releaseSupply() public {
        require(block.timestamp >= releaseStartTime, "Supply release has not started yet");
        require(block.timestamp <= releaseEndTime, "Supply release has ended");

        currentSupply += monthlyReleaseAmount;
        balanceOf[msg.sender] += monthlyReleaseAmount;
        
        // Halve the monthly release amount
        monthlyReleaseAmount /= 2;
    }
}