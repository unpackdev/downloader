// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ITornStaking {
  function checkReward(address user) external view returns (uint256 amount);

  function getReward() external;

  function accumulatedRewards(address user) external view returns (uint256 amount);

  function accumulatedRewardPerTorn() external view returns (uint256);

  function accumulatedRewardRateOnLastUpdate(address user) external view returns (uint256);

  function addBurnRewards(uint256 amount) external;

  function updateRewardsOnLockedBalanceChange(address account, uint256 amountLockedBeforehand) external;
}
