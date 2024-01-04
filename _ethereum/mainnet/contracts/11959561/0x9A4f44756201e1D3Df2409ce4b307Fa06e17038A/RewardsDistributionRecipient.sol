// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


abstract contract RewardsDistributionRecipient {
  address public immutable rewardsDistribution;

  function notifyRewardAmount(uint256 reward) external virtual;

  constructor(address rewardsDistribution_) public {
    rewardsDistribution = rewardsDistribution_;
  }

  modifier onlyRewardsDistribution() {
    require(
      msg.sender == rewardsDistribution,
      "Caller is not RewardsDistribution contract"
    );
    _;
  }
}
