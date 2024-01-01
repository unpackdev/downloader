// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStakingPool {
    struct _deposit {
        uint256 rewardPerShare;
        uint256 stakedAmount;
        uint256 earned;
        uint256 claimed;
    }

    struct _state {
        uint256 totalStaked;
        uint256 rewardPerShare;
        uint256 totalRewards;
    }

    function state() external view returns (_state memory);

    function totalStaked() external view returns (uint256);

    function userStakes(address user) external view returns (_deposit memory);
}

contract StakingHelper {
    IStakingPool public pool;

    constructor(address _pool) {
        pool = IStakingPool(_pool);
    }

    function balanceOf(address user) public view returns (uint256) {
        return pool.userStakes(user).stakedAmount;
    }

    function totalSupply() public view returns (uint256) {
        return pool.state().totalStaked;
    }

    function name() public pure returns (string memory) {
        return "Staked wiskers";
    }

    function symbol() public pure returns (string memory) {
        return "sWSKR";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}