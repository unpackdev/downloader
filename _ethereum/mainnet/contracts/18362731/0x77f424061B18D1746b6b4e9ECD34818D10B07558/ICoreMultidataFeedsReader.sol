// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./IVersioned.sol";


/// @title Reader of MultidataFeeds core data.
interface ICoreMultidataFeedsReader is IVersioned {

    struct Metric {
        string name;    // unique, immutable in a contract
        string description;
        string currency;    // USD, ETH, PCT (for percent), BPS (for basis points), etc
        string[] tags;
    }

    struct Quote {
        uint256 value;
        uint32 updateTS;
    }

    event NewMetric(string name);
    event MetricInfoUpdated(string name);
    /// @notice updated one metric or all if metricId=type(uint256).max-1
    event MetricUpdated(uint indexed epochId, uint indexed metricId);


    /**
     * @notice Gets a list of metrics quoted by this oracle.
     * @return A list of metric info indexed by numerical metric ids.
     */
    function getMetrics() external view returns (Metric[] memory);

    /// @notice Gets a count of metrics quoted by this oracle.
    function getMetricsCount() external view returns (uint);

    /// @notice Gets metric info by a numerical id.
    function getMetric(uint256 id) external view returns (Metric memory);

    /**
     * @notice Checks if a metric is quoted by this oracle.
     * @param name Metric codename.
     * @return has `true` if metric exists.
     * @return id Metric numerical id, set if `has` is true.
     */
    function hasMetric(string calldata name) external view returns (bool has, uint256 id);

    /**
     * @notice Gets last known quotes for specified metrics.
     * @param names Metric codenames to query.
     * @return quotes Values and update timestamps for queried metrics.
     */
    function quoteMetrics(string[] calldata names) external view returns (Quote[] memory quotes);

    /**
     * @notice Gets last known quotes for specified metrics by internal numerical ids.
     * @dev Saves one storage lookup per metric.
     * @param ids Numerical metric ids to query.
     * @return quotes Values and update timestamps for queried metrics.
     */
    function quoteMetrics(uint256[] calldata ids) external view returns (Quote[] memory quotes);
}
