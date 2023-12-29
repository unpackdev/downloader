// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IStaking {
    function updateReward(uint256 _amount) external;

    function init(address _rewardToken, address _stakingToken) external;
}
