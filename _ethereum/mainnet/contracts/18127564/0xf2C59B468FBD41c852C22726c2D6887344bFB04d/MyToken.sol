// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract MyToken {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }
}