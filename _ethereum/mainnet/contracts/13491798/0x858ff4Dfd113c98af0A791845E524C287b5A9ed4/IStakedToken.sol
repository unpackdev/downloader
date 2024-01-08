// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IStakedToken {
    function stake(address to, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;

    function stakersCooldowns(address staker) external view returns (uint256);

    function COOLDOWN_SECONDS() external view returns (uint256);

    function UNSTAKE_WINDOW() external view returns (uint256);
}
