// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface IGauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint) external;
}
