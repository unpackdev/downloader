// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccountDetails {
    mapping(address => uint256) public accountBalances;

    function getBalance(address account) public view returns (uint256) {
        return accountBalances[account];
    }

    function deposit() public payable {
        accountBalances[msg.sender] += msg.value;
    }
}