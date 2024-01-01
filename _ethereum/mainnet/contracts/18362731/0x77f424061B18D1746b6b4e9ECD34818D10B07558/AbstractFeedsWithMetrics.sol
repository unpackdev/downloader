// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./ICoreMultidataFeedsReader.sol";


abstract contract AbstractFeedsWithMetrics is ICoreMultidataFeedsReader {

    Metric[] internal metrics;
    // Position of the metric in the `metrics` array, plus 1 because index 0
    // means that metric is not exists (to avoid additional checks of existence).
    mapping(string => uint) internal adjustedMetricId;

    /// @inheritdoc ICoreMultidataFeedsReader
    function getMetrics() public view override returns (Metric[] memory) {
        return metrics;
    }

    /// @inheritdoc ICoreMultidataFeedsReader
    function getMetricsCount() public view override returns (uint) {
        return metrics.length;
    }

    /// @inheritdoc ICoreMultidataFeedsReader
    function getMetric(uint256 id) external view override returns (Metric memory) {
        require(id < metrics.length, "MultidataFeeds: METRIC_NOT_FOUND");
        return metrics[id];
    }

    /// @inheritdoc ICoreMultidataFeedsReader
    function hasMetric(string calldata name) public view override returns (bool has, uint256 id) {
        uint adjustedId = adjustedMetricId[name];
        if (adjustedId != 0) {
            return (true, adjustedId - 1);
        }

        return (false, 0);
    }

    function addMetric(Metric memory metric_) internal returns (uint newMetricId_) {
        uint adjustedId = adjustedMetricId[metric_.name];
        require(adjustedId == 0, "MultidataFeeds: METRIC_EXISTS");

        newMetricId_ = metrics.length;
        adjustedMetricId[metric_.name] = newMetricId_ + 1;
        metrics.push(metric_);

        emit NewMetric(metric_.name);
    }

    function updateMetric(Metric memory metric_) internal {
        uint adjustedId = adjustedMetricId[metric_.name];
        require(adjustedId != 0, "MultidataFeeds: METRIC_NOT_FOUND");

        metrics[adjustedId-1] = metric_;
        emit MetricInfoUpdated(metric_.name);
    }
}
