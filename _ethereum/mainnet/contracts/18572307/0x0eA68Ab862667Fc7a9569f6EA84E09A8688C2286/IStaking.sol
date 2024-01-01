// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./IERC20.sol";

interface IStaking {
    function addReward(uint256 amount) external;

    function stake(uint256 amount) external;

    function unstake() external;

    function requestUnstake(uint256 amount) external;

    function claimReward() external returns (uint256);

    function calculateRewardsEarned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}
