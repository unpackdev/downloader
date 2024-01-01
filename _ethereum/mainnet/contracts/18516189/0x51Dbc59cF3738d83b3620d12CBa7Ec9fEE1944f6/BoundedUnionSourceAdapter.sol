// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./SignedMath.sol";

import "./IAggregatorV3Source.sol";
import "./IMedian.sol";
import "./IPyth.sol";
import "./ChainlinkSourceAdapter.sol";
import "./ChronicleMedianSourceAdapter.sol";
import "./PythSourceAdapter.sol";
import "./SnapshotSource.sol";

/**
 * @title BoundedUnionSourceAdapter contract to read data from multiple sources and return the newest, contingent on it
 * being within a certain tolerance of the other sources. The return logic operates as follows:
 *   a) Return the most recent price if it's within tolerance of at least one of the other two.
 *   b) If not, return the second most recent price if it's within tolerance of at least one of the other two.
 *   c) If neither a) nor b) is met, return the chainlink price.
 * @dev This adapter only works with Chainlink, Chronicle and Pyth adapters. If alternative adapter configs are desired
 * then a new adapter should be created.
 */

abstract contract BoundedUnionSourceAdapter is
    ChainlinkSourceAdapter,
    ChronicleMedianSourceAdapter,
    PythSourceAdapter
{
    uint256 public immutable BOUNDING_TOLERANCE;

    constructor(
        IAggregatorV3Source chainlink,
        IMedian chronicle,
        IPyth pyth,
        bytes32 pythPriceId,
        uint256 boundingTolerance
    ) ChainlinkSourceAdapter(chainlink) ChronicleMedianSourceAdapter(chronicle) PythSourceAdapter(pyth, pythPriceId) {
        BOUNDING_TOLERANCE = boundingTolerance;
    }

    /**
     * @notice Returns the latest data from the source, contingent on it being within a tolerance of the other sources.
     * @return answer The latest answer in 18 decimals.
     * @return timestamp The timestamp of the answer.
     */
    function getLatestSourceData()
        public
        view
        override(ChainlinkSourceAdapter, ChronicleMedianSourceAdapter, PythSourceAdapter)
        returns (int256 answer, uint256 timestamp)
    {
        (int256 clAnswer, uint256 clTimestamp) = ChainlinkSourceAdapter.getLatestSourceData();
        (int256 crAnswer, uint256 crTimestamp) = ChronicleMedianSourceAdapter.getLatestSourceData();
        (int256 pyAnswer, uint256 pyTimestamp) = PythSourceAdapter.getLatestSourceData();

        return _selectBoundedPrice(clAnswer, clTimestamp, crAnswer, crTimestamp, pyAnswer, pyTimestamp);
    }

    /**
     * @notice Snapshots is a no-op for this adapter as its never used.
     */
    function snapshotData() public override(ChainlinkSourceAdapter, SnapshotSource) {}

    /**
     * @notice Tries getting latest data as of requested timestamp. Note that for all historic lookups we simply return
     * the Chainlink data as this is the only supported source that has historical data.
     * @param timestamp The timestamp to try getting latest data at.
     * @param maxTraversal The maximum number of rounds to traverse when looking for historical data.
     * @return answer The answer as of requested timestamp, or earliest available data if not available, in 18 decimals.
     * @return updatedAt The timestamp of the answer.
     */
    function tryLatestDataAt(uint256 timestamp, uint256 maxTraversal)
        public
        view
        override(ChainlinkSourceAdapter, ChronicleMedianSourceAdapter, PythSourceAdapter)
        returns (int256, uint256)
    {
        // Chainlink has price history, so use tryLatestDataAt to pull the most recent price that satisfies the timestamp constraint.
        (int256 clAnswer, uint256 clTimestamp) = ChainlinkSourceAdapter.tryLatestDataAt(timestamp, maxTraversal);

        // For Chronicle and Pyth, just pull the most recent prices and drop them if they don't satisfy the constraint.
        (int256 crAnswer, uint256 crTimestamp) = ChronicleMedianSourceAdapter.getLatestSourceData();
        (int256 pyAnswer, uint256 pyTimestamp) = PythSourceAdapter.getLatestSourceData();

        // To "drop" Chronicle and Pyth, we set their timestamps to 0 (as old as possible) if they are too recent.
        // This means that they will never be used if either or both are 0.
        if (crTimestamp > timestamp) crTimestamp = 0;
        if (pyTimestamp > timestamp) pyTimestamp = 0;

        return _selectBoundedPrice(clAnswer, clTimestamp, crAnswer, crTimestamp, pyAnswer, pyTimestamp);
    }

    // Selects the appropriate price from the three sources based on the bounding tolerance and logic.
    function _selectBoundedPrice(int256 cl, uint256 clT, int256 cr, uint256 crT, int256 py, uint256 pyT)
        internal
        view
        returns (int256, uint256)
    {
        int256 newestVal = 0;
        uint256 newestT = 0;

        // For each price, check if it is within tolerance of the other two. If so, check if it is the newest.
        if (pyT > newestT && (_withinTolerance(py, cr) || _withinTolerance(py, cl))) (newestVal, newestT) = (py, pyT);
        if (crT > newestT && (_withinTolerance(cr, py) || _withinTolerance(cr, cl))) (newestVal, newestT) = (cr, crT);
        if (clT > newestT && (_withinTolerance(cl, py) || _withinTolerance(cl, cr))) (newestVal, newestT) = (cl, clT);

        if (newestT == 0) return (cl, clT); // If no valid price was found, default to returning chainlink.

        return (newestVal, newestT);
    }

    // Checks if value a is within tolerance of value b.
    function _withinTolerance(int256 a, int256 b) internal view returns (bool) {
        uint256 diff = SignedMath.abs(a - b);
        uint256 maxDiff = SignedMath.abs(b) * BOUNDING_TOLERANCE / 1e18;
        return diff <= maxDiff;
    }
}
