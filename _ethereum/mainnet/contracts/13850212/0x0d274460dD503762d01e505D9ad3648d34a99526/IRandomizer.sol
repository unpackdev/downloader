// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function random(uint256 seed, uint64 timestamp, uint64 blockNumber) external returns (uint256);
}