// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IRewarder {
    function onSushiReward(
        uint256 pid,
        address user,
        address recipient,
        uint256 sushiAmount,
        uint256 newLpAmount
    ) external;
}
