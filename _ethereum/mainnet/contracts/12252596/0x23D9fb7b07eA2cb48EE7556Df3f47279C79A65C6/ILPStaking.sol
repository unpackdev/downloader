// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface ILPStaking {
    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RewardStreamStarted(address indexed user, uint amount);
    event RewardStreamStopped(address indexed user);
    event RewardPaid(address indexed user, uint reward);
}
