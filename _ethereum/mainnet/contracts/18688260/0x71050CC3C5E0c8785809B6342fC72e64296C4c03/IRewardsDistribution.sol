// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IRewardsDistribution {
    function notifyRewardAmount(uint256 reward) external;

    function totalSupply() external view returns (uint256);

    function stakingToken() external view returns (IERC20);

    function rewardsToken() external view returns (IERC20);

    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;
}
