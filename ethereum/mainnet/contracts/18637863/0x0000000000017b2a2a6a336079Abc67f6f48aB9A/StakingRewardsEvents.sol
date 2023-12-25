// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IStakingRewards.sol";

/// @title StakingRewardsEvents
/// @notice All the events used in `StakingRewards` contract
contract StakingRewardsEvents {
    event RewardAdded(uint256 reward);

    event Staked(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount);

    event RewardPaid(address indexed user, uint256 reward);

    event Recovered(address indexed tokenAddress, address indexed to, uint256 amount);

    event RewardsDistributionUpdated(address indexed _rewardsDistribution);
}
