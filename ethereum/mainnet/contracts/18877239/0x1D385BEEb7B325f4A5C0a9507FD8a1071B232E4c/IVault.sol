// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IVault {
    function deposit(uint amount, address receiver) external returns (uint);
}