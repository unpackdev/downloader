// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

interface LotteryHistoryInterface {
    function newBet(uint32, uint8, address, uint256, address) external;
    function roundStarted(uint32, uint) external;
    function roundEnded(uint32, uint256, uint256, uint256) external;
}