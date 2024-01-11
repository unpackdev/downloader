// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumUnlocked {
    function mint(address to, uint128 dropId, uint256 variant) external returns (uint256);
}