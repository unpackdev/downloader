// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEGMCShareholderDistributor {
    function getAmounts() external view returns (uint lpAmount, uint devAmount, uint tokenAmount);
    function distribute() external returns (uint lpAmount, uint tokenAmount);
}