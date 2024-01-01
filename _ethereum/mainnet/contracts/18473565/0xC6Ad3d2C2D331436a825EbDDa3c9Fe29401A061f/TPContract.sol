// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract TPContract {
    function getTPMessage() public pure returns (string memory) {
        return "365 TPs in 365 Days - a TP a day keeps the brokies away";
    }
}
