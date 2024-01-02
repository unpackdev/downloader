// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IStakingRewards {
    function getReward(address _staker) external view returns (uint256);

    function claimReward() external;
}
