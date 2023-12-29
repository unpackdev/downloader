// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IMultiplier.sol";
import "./IPenaltyFee.sol";

interface IStakingPool {
    struct StakingInfo {
        uint256 stakedAmount; // amount of the stake
        uint256 minimumStakeTimestamp; // timestamp of the minimum stake
        uint256 duration; // in seconds
        uint256 rewardPerTokenPaid; // Reward per token paid
        uint256 rewards; // rewards to be claimed
    }

    function rewardsMultiplier() external view returns (IMultiplier);

    function penaltyFeeCalculator() external view returns (IPenaltyFee);

    event Staked(address indexed user, uint256 stakeNumber, uint256 amount);
    event Unstaked(address indexed user, uint256 stakeNumber, uint256 amount);
    event RewardPaid(address indexed user, uint256 stakeNumber, uint256 reward);
}
