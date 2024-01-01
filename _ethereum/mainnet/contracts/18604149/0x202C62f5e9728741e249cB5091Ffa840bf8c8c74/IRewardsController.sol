// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardsController {
  function claimAllRewardsToSelf(
    address[] calldata assets
  ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  function getAllUserRewards(
    address[] calldata assets,
    address user
  )
    external
    view
    returns (address[] memory rewardsList, uint256[] memory unclaimedAmounts);
}
