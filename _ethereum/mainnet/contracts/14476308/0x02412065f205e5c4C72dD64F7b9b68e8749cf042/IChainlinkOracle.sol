// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

interface IChainlinkOracle {
    function latestAnswer() external view returns (int256);
}