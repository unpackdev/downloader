// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStakingPool {
    struct _deposit {
        uint256 rewardPerShare;
        uint256 stakedAmount;
        uint256 earned;
        uint256 claimed;
    }

    function userStakes(address user) external returns (_deposit memory);
}

contract StakingHelper {
    IStakingPool public pool;

    constructor(address _pool) {
        pool = IStakingPool(_pool);
    }

    function balanceOf(address user) public returns (uint256) {
        return pool.userStakes(user).stakedAmount;
    }
}