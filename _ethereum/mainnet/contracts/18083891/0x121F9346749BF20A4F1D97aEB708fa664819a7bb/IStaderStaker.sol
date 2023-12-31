// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IStader {
    function deposit(address receipient) external payable returns (uint256);
}