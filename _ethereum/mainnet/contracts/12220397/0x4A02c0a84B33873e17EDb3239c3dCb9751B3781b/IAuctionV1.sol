// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IAuctionV1 {
    function callIncomeDailyTokensTrigger(uint256 amount) external;

    function callIncomeWeeklyTokensTrigger(uint256 amount) external;
}
