// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface IRewardsDistributionRecipient {
    function notifyRewardAmount(uint256 reward) external;
    function periodFinish() external view returns (uint);
}
