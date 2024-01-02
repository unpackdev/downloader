// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracleNetwork {
    function latestTotalBalance()
        external
        view
        returns (uint256 totalBalance, uint64 timestamp);
}
