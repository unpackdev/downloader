// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract IPlanetRewards {
    struct Account {
        uint256 lastStakedAt;
        uint256 totalStaked;
        uint256 creditedPoints;
    }

    event Stake(address indexed staker, uint256 amount, uint256 totalCreditedPoints, uint256 timestamp);
    event Unstake(address indexed staker, uint256 amount, uint256 timestamp);
    event StakingEnabled(bool enabled);
    event ResetWinner(address winner);

    error InvalidStakingAmount();
    error NoStakedTokens();
    error StakingNotEnabled();
    error UnstakingNotPermitted();
    error ZeroValue();
}
