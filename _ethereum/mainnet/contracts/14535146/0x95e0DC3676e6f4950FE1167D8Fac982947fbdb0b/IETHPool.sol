// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IETHPool {

    event Staked(address user, uint256 stakeId, uint256 amount, uint256 timestamp);

    event Unstaked(address user, uint256 stakeId, uint256 amount, uint256 timestamp);

    function stake(uint256 amount) external payable;

    function unStake(uint256[] memory stakeIds) external payable;

}