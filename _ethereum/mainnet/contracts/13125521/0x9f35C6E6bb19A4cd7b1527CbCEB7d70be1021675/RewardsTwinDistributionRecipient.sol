// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

abstract contract RewardsTwinDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward, uint256 _rewardsDuration) external virtual;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
}