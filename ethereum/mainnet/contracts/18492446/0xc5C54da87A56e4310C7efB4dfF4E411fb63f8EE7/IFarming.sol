// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFarming {
    event Deposit(address indexed _user, uint256 indexed _pid, uint256 _amount);
    event Withdraw(address indexed _user, uint256 indexed _pid, uint256 _amount);
    event EmergencyWithdraw(address indexed _user, uint256 indexed _pid, uint256 _amount);
}