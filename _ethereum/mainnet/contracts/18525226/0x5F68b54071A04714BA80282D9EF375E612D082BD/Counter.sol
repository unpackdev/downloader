// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract Counter {
    uint256 public count = 1;

    function increment() public {
        count += 1;
    }
}