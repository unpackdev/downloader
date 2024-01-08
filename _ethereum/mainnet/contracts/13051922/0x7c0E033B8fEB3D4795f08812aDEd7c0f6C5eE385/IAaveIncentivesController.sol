// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAaveIncentivesController {
    function getRewardsBalance(address[] calldata assets, address user) external returns (uint256);
    function claimRewards(address[] calldata assets, uint256 amount, address to) external;
}