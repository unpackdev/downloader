// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

abstract contract RewardsDistributionRecipient {
  address public rewardsDistribution;

  function notifyRewardAmount(uint256 rewardDPX, uint256 rewardRDPX) external virtual;

  modifier onlyRewardsDistribution() {
    require(msg.sender == rewardsDistribution, 'Caller is not RewardsDistribution contract');
    _;
  }
}
