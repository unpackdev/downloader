// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IFirstPhase {
    event Record(address account, uint256 amount);
    event Records(address[] account, uint256[] amount);

    event Withdraw(address account, uint256 amount);
}
