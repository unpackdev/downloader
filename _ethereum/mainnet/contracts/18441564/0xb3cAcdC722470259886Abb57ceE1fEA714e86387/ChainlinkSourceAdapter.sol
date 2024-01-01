// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./DecimalLib.sol";
import "./IAggregatorV3Source.sol";
import "./DiamondRootOevShare.sol";

/**
 * @title ChainlinkSourceAdapter contract to read data from Chainlink aggregator and standardize it for the OEV.
 * @dev Can fetch information from Chainlink source at a desired timestamp for historic lookups.
 */

abstract contract ChainlinkSourceAdapter is DiamondRootOevShare {
    IAggregatorV3Source public immutable CHAINLINK_SOURCE;
    uint8 private immutable SOURCE_DECIMALS;

    // As per Chainlink documentation https://docs.chain.link/data-feeds/historical-data#roundid-in-proxy
    // roundId on the aggregator proxy is comprised of phaseId (higher 16 bits) and roundId from phase aggregator
    // (lower 64 bits). PHASE_MASK is used to calculate first roundId of current phase aggregator.
    uint80 private constant PHASE_MASK = uint80(0xFFFF) << 64;

    event SourceSet(address indexed sourceOracle, uint8 indexed sourceDecimals);

    constructor(IAggregatorV3Source source) {
        CHAINLINK_SOURCE = source;
        SOURCE_DECIMALS = source.decimals();

        emit SourceSet(address(source), SOURCE_DECIMALS);
    }

    /**
     * @notice Tries getting latest data as of requested timestamp. If this is not possible, returns the earliest data
     * available past the requested timestamp within provided traversal limitations.
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
        (int256 answer, uint256 updatedAt) = _tryLatestRoundDataAt(timestamp, maxTraversal);
        return (DecimalLib.convertDecimals(answer, SOURCE_DECIMALS, 18), updatedAt);
    }

    /**
     * @notice Initiate a snapshot of the source data. This is a no-op for Chainlink.
     */
    function snapshotData() public virtual override {}

    /**
     * @notice Returns the latest data from the source.
     * @return answer The latest answer in 18 decimals.
     * @return updatedAt The timestamp of the answer.
     */
    function getLatestSourceData() public view virtual override returns (int256, uint256) {
        (, int256 sourceAnswer,, uint256 updatedAt,) = CHAINLINK_SOURCE.latestRoundData();
        return (DecimalLib.convertDecimals(sourceAnswer, SOURCE_DECIMALS, 18), updatedAt);
    }

    // Tries getting latest data as of requested timestamp. If this is not possible, returns the earliest data available
    // past the requested timestamp considering the maxTraversal limitations.
    function _tryLatestRoundDataAt(uint256 timestamp, uint256 maxTraversal) internal view returns (int256, uint256) {
        (uint80 roundId, int256 answer,, uint256 updatedAt,) = CHAINLINK_SOURCE.latestRoundData();

        // In the happy path there have been no source updates since requested time, so we can return the latest data.
        // We can use updatedAt property as it matches the block timestamp of the latest source transmission.
        if (updatedAt <= timestamp) return (answer, updatedAt);

        // Attempt traversing historical round data backwards from roundId. This might still be newer or uninitialized.
        (int256 historicalAnswer, uint256 historicalUpdatedAt) = _searchRoundDataAt(timestamp, roundId, maxTraversal);

        // Validate returned data. If it is uninitialized we fallback to returning the current latest round data.
        if (historicalUpdatedAt > 0) return (historicalAnswer, historicalUpdatedAt);
        return (answer, updatedAt);
    }

    // Tries finding latest historical data (ignoring current roundId) not newer than requested timestamp. Might return
    // newer data than requested if exceeds traversal or hold uninitialized data that should be handled by the caller.
    function _searchRoundDataAt(uint256 timestamp, uint80 targetRoundId, uint256 maxTraversal)
        internal
        view
        returns (int256, uint256)
    {
        uint80 roundId;
        int256 answer;
        uint256 updatedAt;
        uint80 traversedRounds = 0;
        uint80 startRoundId = (targetRoundId & PHASE_MASK) + 1; // Phase aggregators are starting at round 1.

        while (traversedRounds < uint80(maxTraversal) && targetRoundId > startRoundId) {
            targetRoundId--; // We started from latest roundId that should be ignored.
            // The aggregator proxy does not keep track when its phase aggregators got switched. This means that we can
            // only traverse rounds of the current phase aggregator. When phase aggregators are switched there is
            // normally an overlap period when both new and old phase aggregators receive updates. Without knowing exact
            // time when the aggregator proxy switched them we might end up returning historical data from the new phase
            // aggregator that was not yet available on the aggregator proxy at the requested timestamp.

            (roundId, answer,, updatedAt,) = CHAINLINK_SOURCE.getRoundData(targetRoundId);
            if (!(roundId == targetRoundId && updatedAt > 0)) return (0, 0);
            if (updatedAt <= timestamp) return (answer, updatedAt);
            traversedRounds++;
        }

        return (answer, updatedAt); // Did not find requested round. Return earliest round or uninitialized data.
    }
}
