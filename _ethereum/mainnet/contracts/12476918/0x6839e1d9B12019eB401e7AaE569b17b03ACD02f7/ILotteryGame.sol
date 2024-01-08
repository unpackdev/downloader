// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ILotteryGame {
    function lockTransfer() external;

    function unlockTransfer() external;

    function startGame() external payable;

    function restartProvableQuery() external payable;
}
