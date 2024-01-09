// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IAngleMiddlemanGauge {
    function notifyReward(address gauge, uint256 amount) external;
}
