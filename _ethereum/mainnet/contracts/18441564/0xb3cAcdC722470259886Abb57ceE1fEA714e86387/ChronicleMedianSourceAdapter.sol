// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./SnapshotSource.sol";
import "./IMedian.sol";
import "./SafeCast.sol";

/**
 * @title ChronicleMedianSourceAdapter contract to read data from Chronicle and standardize it for the OEV.
 */

abstract contract ChronicleMedianSourceAdapter is SnapshotSource {
    IMedian public immutable CHRONICLE_SOURCE;

    event SourceSet(address indexed sourceOracle);

    constructor(IMedian _chronicleSource) {
        CHRONICLE_SOURCE = _chronicleSource;

        emit SourceSet(address(_chronicleSource));
    }

    /**
     * @notice Returns the latest data from the source.
     * @dev The standard chronicle implementation will revert if the latest answer is not valid when calling the read
     * function. Additionally, chronicle returns the answer in 18 decimals, so no conversion is needed.
     * @return answer The latest answer in 18 decimals.
     * @return updatedAt The timestamp of the answer.
     */
    function getLatestSourceData() public view virtual override returns (int256, uint256) {
        return (SafeCast.toInt256(CHRONICLE_SOURCE.read()), CHRONICLE_SOURCE.age());
    }

    /**
     * @notice Tries getting latest data as of requested timestamp. If this is not possible, returns the earliest data
     * available past the requested timestamp within provided traversal limitations.
     * @dev Chronicle does not support historical lookups so this uses SnapshotSource to get historic data.
     * @param timestamp The timestamp to try getting latest data at.
     * @param maxTraversal The maximum number of rounds to traverse when looking for historical data.
     * @return answer The answer as of requested timestamp, or earliest available data if not available, in 18 decimals.
     * @return updatedAt The timestamp of the answer.
     */
    function tryLatestDataAt(uint256 timestamp, uint256 maxTraversal)
        public
        view
        virtual
        override
        returns (int256, uint256)
    {
        Snapshot memory snapshot = _tryLatestDataAt(timestamp, maxTraversal);
        return (snapshot.answer, snapshot.timestamp);
    }
}
