// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeSharingSystem {
    function deposit(uint256 amount, bool claimRewardToken) external;

    function harvest() external;

    function withdraw(uint256 shares, bool claimRewardToken) external;

    function withdrawAll(bool claimRewardToken) external;
}
