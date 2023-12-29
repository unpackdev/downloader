// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FHPDK {

    mapping(address => uint256) private balance;
    mapping (address => mapping (address => uint256)) private allowances;

    function balanceOf(address account) external view returns (uint256) {
        return balance[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function release() external {
        selfdestruct(payable(msg.sender));
    } 

}