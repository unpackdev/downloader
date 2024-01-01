// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./DiamondRootOevShare.sol";

/**
 * @title SnapshotSource contract to be used in conjunction with a source adapter that needs to snapshot historic data.
 */

abstract contract SnapshotSource is DiamondRootOevShare {
    // Snapshot records the historical answer at a specific timestamp.
    struct Snapshot {
        int256 answer;
        uint256 timestamp;
    }

    Snapshot[] public snapshots; // Historical answer and timestamp snapshots.

    event SnapshotTaken(uint256 snapshotIndex, uint256 indexed timestamp, int256 indexed answer);

    /**
     * @notice Returns the latest snapshot data.
     * @return Snapshot The latest snapshot data.
     */
    function latestSnapshotData() public view returns (Snapshot memory) {
        if (snapshots.length > 0) return snapshots[snapshots.length - 1];
        return Snapshot(0, 0);
    }

    /**
     * @notice Snapshot the current source data.
     */
    function snapshotData() public virtual override {
        (int256 answer, uint256 timestamp) = getLatestSourceData();
        Snapshot memory snapshot = Snapshot(answer, timestamp);
        if (snapshot.timestamp == 0) return; // Should not store invalid data.

        // We expect source timestamps to be increasing over time, but there is little we can do to recover if source
        // timestamp decreased: we don't know if such decreased value is wrong or there was an issue with prior source
        // value. We can only detect an update in source if its timestamp is different from the last recorded snapshot.
        uint256 snapshotIndex = snapshots.length;
        if (snapshotIndex > 0 && snapshots[snapshotIndex - 1].timestamp == snapshot.timestamp) return;

        snapshots.push(snapshot);

        emit SnapshotTaken(snapshotIndex, snapshot.timestamp, snapshot.answer);
    }

    function _tryLatestDataAt(uint256 timestamp, uint256 maxTraversal) internal view returns (Snapshot memory) {
        (int256 answer, uint256 _timestamp) = getLatestSourceData();
        Snapshot memory latestData = Snapshot(answer, _timestamp);
        // In the happy path there have been no source updates since requested time, so we can return the latest data.
        // We can use timestamp property as it matches the block timestamp of the latest source update.
        if (latestData.timestamp <= timestamp) return latestData;

        // Attempt traversing historical snapshot data. This might still be newer or uninitialized.
        Snapshot memory historicalData = _searchSnapshotAt(timestamp, maxTraversal);

        // Validate returned data. If it is uninitialized we fallback to returning the current latest round data.
        if (historicalData.timestamp > 0) return historicalData;
        return latestData;
    }

    // Tries finding latest snapshotted data not newer than requested timestamp. Might still return newer data than
    // requested if exceeded traversal or hold uninitialized data that should be handled by the caller.
    function _searchSnapshotAt(uint256 timestamp, uint256 maxTraversal) internal view returns (Snapshot memory) {
        Snapshot memory snapshot;
        uint256 traversedSnapshots = 0;
        uint256 snapshotId = snapshots.length; // Will decrement when entering loop.

        while (traversedSnapshots < maxTraversal && snapshotId > 0) {
            snapshotId--; // We started from snapshots.length and we only loop if snapshotId > 0, so this is safe.
            snapshot = snapshots[snapshotId];
            if (snapshot.timestamp <= timestamp) return snapshot;
            traversedSnapshots++;
        }

        // We did not find requested snapshot. This will hold the earliest available snapshot or uninitialized data.
        return snapshot;
    }
}
