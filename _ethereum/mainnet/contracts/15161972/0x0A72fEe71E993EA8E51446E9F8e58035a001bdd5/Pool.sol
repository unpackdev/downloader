// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Math.sol";

library Pool {

    struct PoolState {
        uint8 mutex;
        uint64 periodFinish;
        uint64 rewardsDuration;
        uint64 lastUpdateTime;
        uint160 distributor;
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
    }

    function lastTimeRewardApplicable(PoolState storage state) internal view returns (uint256)
    {
        return Math.min(block.timestamp, state.periodFinish);
    }

    function rewardPerToken(PoolState storage state, uint256 totalSupply) internal view returns (uint256)
    {
        if (totalSupply == 0) return state.rewardPerTokenStored;

        return state.rewardPerTokenStored + (
            (Math.min(block.timestamp, state.periodFinish) - state.lastUpdateTime) * state.rewardRate * 1e18 / totalSupply
        );
    }

    function getRewardForDuration(PoolState storage state) internal view returns (uint256)
    {
        return state.rewardRate * state.rewardsDuration;
    }

    function updateReward(PoolState storage state, uint256 supply) internal
    {
        state.rewardPerTokenStored = rewardPerToken(state, supply);
        state.lastUpdateTime = uint64(lastTimeRewardApplicable(state));
    }
}