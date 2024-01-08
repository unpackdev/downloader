// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

interface IGlobalPool {

    event StakePending(address indexed staker, uint256 amount);
    event RewardClaimed(address indexed staker, uint256 amount);

    function stake(uint256 amount) external payable;

    function unstake(uint256 amount, uint256 fee, uint256 useBeforeBlock, bytes memory signature) external;
}
