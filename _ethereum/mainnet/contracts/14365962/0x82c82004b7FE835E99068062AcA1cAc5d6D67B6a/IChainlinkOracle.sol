// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IChainlinkOracle {
    function latestAnswer() external view returns (uint256);
}
