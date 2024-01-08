// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Bounds.sol";

interface IAloePredictionsDerivedState {
    /**
     * @notice The most recent crowdsourced prediction
     * @return (prediction bounds, whether bounds prices are inverted)
     */
    function current() external view returns (Bounds memory, bool);

    /// @notice The earliest time at which the epoch can end
    function epochExpectedEndTime() external view returns (uint32);

    /**
     * @notice Aggregates proposals in the current `epoch`. Only the top `NUM_PROPOSALS_TO_AGGREGATE`, ordered by
     * stake, will be considered (though others can still receive rewards).
     * @return bounds The crowdsourced price range that may characterize trading activity over the next hour
     */
    function aggregate() external view returns (Bounds memory bounds);

    /**
     * @notice Fetches Uniswap prices over 10 discrete intervals in the past hour. Computes mean and standard
     * deviation of these samples, and returns "ground truth" bounds that should enclose ~95% of trading activity
     * @return bounds The "ground truth" price range that will be used when computing rewards
     * @return shouldInvertPricesNext Whether proposals in the next epoch should be submitted with inverted bounds
     */
    function fetchGroundTruth() external view returns (Bounds memory bounds, bool shouldInvertPricesNext);

    /**
     * @notice Builds a memory array that can be passed to Uniswap V3's `observe` function to specify
     * intervals over which mean prices should be fetched
     * @return secondsAgos From how long ago each cumulative tick and liquidity value should be returned
     */
    function selectedOracleTimetable() external pure returns (uint32[] memory secondsAgos);
}
