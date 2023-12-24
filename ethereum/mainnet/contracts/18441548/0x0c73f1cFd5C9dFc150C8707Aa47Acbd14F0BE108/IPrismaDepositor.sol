// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPrismaDepositor {
   function deposit(uint256 _amount, bool _lock) external;
}