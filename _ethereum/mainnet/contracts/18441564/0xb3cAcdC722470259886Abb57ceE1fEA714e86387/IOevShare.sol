// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IOevShare {
    event LatestValueUnlocked(uint256 indexed timestamp);

    function internalLatestData() external view returns (int256 answer, uint256 timestamp);
}
