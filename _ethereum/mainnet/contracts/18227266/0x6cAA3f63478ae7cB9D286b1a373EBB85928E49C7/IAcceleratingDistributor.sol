// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface IAcceleratingDistributor {
    function stake(address stakedToken, uint256 amount) external;
    function stakeFor(address stakedToken, uint256 amount, address beneficiary) external;
    function unstake(address stakedToken, uint256 amount) external;
    function withdrawReward(address stakedToken) external;
    function exit(address stakedToken) external;
}
