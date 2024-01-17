// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ILockSubscription {
    function processLockEvent(
        address account,
        uint256 lockStart,
        uint256 lockEnd,
        uint256 amount
    ) external;

    function processWitdrawEvent(
        address account,
        uint256 amount
    ) external;
}
