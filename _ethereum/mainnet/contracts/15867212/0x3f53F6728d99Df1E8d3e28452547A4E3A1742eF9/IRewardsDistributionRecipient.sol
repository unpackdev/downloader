// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRewardsDistributionRecipient {
    function notifyRewardAmount(uint256 reward) external;

    function setStrategyWhoCanAutoStake(address addr, bool flag) external;
}
