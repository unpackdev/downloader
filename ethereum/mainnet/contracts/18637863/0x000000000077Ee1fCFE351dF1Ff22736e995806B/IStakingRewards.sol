// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IERC20.sol";

/// @title IStakingRewardsFunctions
/// @notice Interface for the staking rewards contract that interact with the `RewardsDistributor` contract
interface IStakingRewardsFunctions {
    function notifyRewardAmount(uint256 reward) external;

    function recoverERC20(address tokenAddress, address to, uint256 tokenAmount) external;

    function setNewRewardsDistribution(address newRewardsDistribution) external;
}

/// @title IStakingRewards
/// @notice Previous interface with additionnal getters for public variables
interface IStakingRewards is IStakingRewardsFunctions {
    function periodFinish() external view returns (uint256);

    function rewardToken() external view returns (IERC20);

    function getReward() external;

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function stakeOnBehalf(uint256 amount, address staker) external;
}
