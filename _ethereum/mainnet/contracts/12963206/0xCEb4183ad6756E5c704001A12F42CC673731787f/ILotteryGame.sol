// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ILotteryGame {
    function lockTransfer() external;

    function unlockTransfer() external;

    function startGame(uint256 _gasPrice, uint256 _provableGasLimit)
        external
        payable;

    function restartProvableQuery(uint256 _gasPrice, uint256 _provableGasLimit)
        external
        payable;
}
