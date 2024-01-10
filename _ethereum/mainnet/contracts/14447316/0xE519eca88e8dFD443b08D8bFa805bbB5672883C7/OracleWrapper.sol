// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface OracleWrapper {
    function latestAnswer() external view returns (uint128);
}
