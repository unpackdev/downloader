// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasuryContract {
    address public lendingPool;
    address public owner;

    event ReceivedFees(address indexed from, uint256 amount);
    event DistributedEarnings(address indexed to, uint256 amount);

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool, "TreasuryContract: Caller is not the lending pool");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "TreasuryContract: Caller is not the owner");
        _;
    }

    constructor(address lendingPool_) {
        lendingPool = lendingPool_;
        owner = msg.sender;
    }

    function receiveFees(uint256 amount) external onlyLendingPool {
      
        emit ReceivedFees(msg.sender, amount);
    }

    function distributeEarnings(address to, uint256 amount) external onlyOwner {
      
        emit DistributedEarnings(to, amount);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        
    }

    function setLendingPool(address lendingPool_) external onlyOwner {
        lendingPool = lendingPool_;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}