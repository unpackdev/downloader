// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFxnDepositor {
   function deposit(uint256 _amount, bool _lock) external;
}