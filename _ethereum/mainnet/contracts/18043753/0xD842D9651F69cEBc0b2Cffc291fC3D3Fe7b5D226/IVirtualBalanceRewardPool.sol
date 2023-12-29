// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

interface IVirtualBalanceRewardPool {
  function rewardToken() external view returns (IERC20 _rewardToken);
  function earned(address _ad) external view returns (uint256 _reward);
  function getReward() external;
  function queueNewRewards(uint256 _rewards) external;
}
