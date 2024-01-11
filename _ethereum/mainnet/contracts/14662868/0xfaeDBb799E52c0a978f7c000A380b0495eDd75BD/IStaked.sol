// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IStaked {
    event Staked(address indexed user, uint256 amount);

    event Redeem(address indexed user, uint256 amount);

    event RewardsAccrued(address user, uint256 amount);

    event RewardsClaimed(address indexed user, uint256 amount);

    function configure(uint128 emissionPerSecond) external;

    function stake(uint256 amount) external;

    function redeem(uint256 amount) external;

    function claim(uint256 amount) external;

    function claimableRewards(address staker) external view returns (uint256);
}
