// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;


interface IStakingTwinRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256, uint256);

    function balanceOf(address account) external view returns (uint256, uint256);

    // Mutative

    function stake(uint256 amountA, uint256 amountB) external;

    function withdraw(uint256 amountA, uint256 amountB) external;

    function getReward() external;

    function exit() external;
}