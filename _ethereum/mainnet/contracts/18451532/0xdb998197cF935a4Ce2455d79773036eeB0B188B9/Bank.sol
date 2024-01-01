// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint256) public balances;

    function deposit(uint256 amount) public payable {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(msg.value == amount, "Sent Ether amount must match the specified deposit amount");
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance to withdraw");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}