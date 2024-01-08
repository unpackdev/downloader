// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuyBack {
    event BuyBackTriggered(uint256 ethSpent);
    function buyBackTokens() external;
}
