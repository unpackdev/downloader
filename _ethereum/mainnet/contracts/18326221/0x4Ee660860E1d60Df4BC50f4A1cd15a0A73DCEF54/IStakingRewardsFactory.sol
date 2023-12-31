// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IStakingRewardsFactory {
    event Deployed(
        address indexed stakingRewardContract,
        address stakingToken,
        address rewardToken,
        uint256 rewardAmount,
        uint256 rewardsDuration
    );

    event Updated(
        address indexed stakingRewardContract,
        uint256 rewardAmount,
        uint256 rewardsDuration
    );
}
