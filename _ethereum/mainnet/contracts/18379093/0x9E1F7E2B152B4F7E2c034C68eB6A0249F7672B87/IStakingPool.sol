// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IMultiplier.sol";
import "./IPenaltyFee.sol";

interface IStakingPool {
    function balanceOf(address _user) external view returns (uint256);

    function rewardsMultiplier() external view returns (IMultiplier);

    function penaltyFeeCalculator() external view returns (IPenaltyFee);

    function minimumStakeTimestamp(address _beneficiary) external view returns (uint256);

    function userStakeDuration(address _beneficiary) external view returns (uint256);

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 rewardsDuration);
}
