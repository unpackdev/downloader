// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IStakedToken {
    function stake(address to, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;

    function REWARD_TOKEN() external view returns (address);

    function stakersCooldowns(address staker) external view returns (uint256);

    function getTotalRewardsBalance(address staker) external view returns (uint256);
}
