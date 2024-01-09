// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IStaking {
  function rewardsToken() external view returns (address);

  function stakingToken() external view returns (address);

  function totalSupply() external view returns (uint256);

  function rewardsDuration() external view returns (uint256);

  function periodFinish() external view returns (uint256);

  function rewardRate() external view returns (uint256);

  function balanceOf(address) external view returns (uint256);

  function earned(address) external view returns (uint256);

  function stake(uint256) external;

  function getReward() external;

  function withdraw(uint256) external;

  function exit() external;

  function notifyRewardAmount(uint256) external;
}
