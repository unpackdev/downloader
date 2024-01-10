// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract ValidAddress {
    modifier isValidAddress(address addr) {
        require(addr != address(0), "Not a valid address!");
        _;
    }
}
