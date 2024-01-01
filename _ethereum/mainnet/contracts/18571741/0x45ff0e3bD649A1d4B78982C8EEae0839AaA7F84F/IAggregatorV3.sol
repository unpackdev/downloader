// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// chainlink oracles interface
interface IAggregatorV3 {
    function latestAnswer() external view returns (int256);
}
