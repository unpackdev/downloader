// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IStaker {
  struct UserClaimedRewards {
    address reward;
    uint256 amount;
  }

  struct UserClaimableRewards {
    address reward;
    uint256 claimableAmount;
  }

  function queueRewards(address rewardToken, uint256 amount) external returns (bool);

  function stake(uint256 amount, address receiver) external returns (uint256);

  function unstake(uint256 amount, address receiver) external returns (uint256);

  function claimRewards(address reward, address receiver) external returns (uint256);

  function claimAllRewards(address receiver) external returns (UserClaimedRewards[] memory);

  function getUserTotalClaimableRewards(address user) external view returns (UserClaimableRewards[] memory);
}
