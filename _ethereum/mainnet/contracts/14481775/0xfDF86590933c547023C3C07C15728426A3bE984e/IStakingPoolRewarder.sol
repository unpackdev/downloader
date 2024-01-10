// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;

interface IStakingPoolRewarder {
    function onReward(
        uint256 poolId,
        address user,
        uint256 amount
    ) external;
}