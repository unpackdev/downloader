// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEGMCRewardsDistributor {
    function getAmounts() external view returns (uint goldRewards, uint silverRewards);
    function distribute() external returns (uint goldAmount, uint silverAmount);
}