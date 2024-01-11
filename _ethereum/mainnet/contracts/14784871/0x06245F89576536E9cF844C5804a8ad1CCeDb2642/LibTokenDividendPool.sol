// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


library LibTokenDividendPool {
    struct SnapshotInfo {
        uint256 id;
        uint256 totalDividendAmount;
        uint256 timestamp;
    }

    struct Distribution {
        bool exists;
        uint256 totalDistribution;
        uint256 lastBalance;
        mapping (uint256 => uint256) tokensPerWeek;
        mapping (address => uint256) nonClaimedSnapshotIndex;
        SnapshotInfo[] snapshots;
    }
}