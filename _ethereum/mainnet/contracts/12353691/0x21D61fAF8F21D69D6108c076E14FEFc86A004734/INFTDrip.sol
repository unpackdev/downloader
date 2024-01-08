//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

interface INFTDrip {
  function claimAllRewards() external;
  function updateAllRewards(address targetAccount) external;
  function updateReward(address targetReward, address targetAccount) external;
}