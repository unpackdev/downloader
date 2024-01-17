// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// EOAable adds a contract modifier to your contract
// that only allows EOAs to intract with functions using the
// msg.sender == tx.origin method

abstract contract OnlyEOA {
    modifier onlyEOA {
        require(msg.sender == tx.origin, "Only EOA!");
        _;
    }
}