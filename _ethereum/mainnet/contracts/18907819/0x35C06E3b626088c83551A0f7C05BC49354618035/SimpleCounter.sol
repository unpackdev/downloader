// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.22;

contract SimpleCounter {
    uint8 private counter;

    function addOne() external {
       ++counter;
    }

    function get() external view returns (uint8) {
        return counter;
    }
}