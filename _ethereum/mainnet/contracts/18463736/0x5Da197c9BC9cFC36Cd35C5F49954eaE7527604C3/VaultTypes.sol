pragma solidity ^0.8.19;

/// @notice Stores all data from a single strategy
/// @dev Packed in two slots
struct StrategyData {
    /// Slot 0
    /// @notice Maximum percentage available to be lent to strategies(in BPS)
    /// @dev in BPS. uint16 is enough to cover the max BPS value of 10_000
    uint16 strategyDebtRatio;
    /// @notice The performance fee
    /// @dev in BPS. uint16 is enough to cover the max BPS value of 10_000
    uint16 strategyPerformanceFee;
    /// @notice Timestamp when the strategy was added.
    /// @dev Overflowing July 21, 2554
    uint48 strategyActivation;
    /// @notice block.timestamp of the last time a report occured
    /// @dev Overflowing July 21, 2554
    uint48 strategyLastReport;
    /// @notice Upper limit on the increase of debt since last harvest
    /// @dev max debt per harvest to be set to a maximum value of 4,722,366,482,869,645,213,695
    uint128 strategyMaxDebtPerHarvest;
    /// Slot 1
    /// @notice Lower limit on the increase of debt since last harvest
    /// @dev min debt per harvest to be set to a maximum value of 16,777,215
    uint128 strategyMinDebtPerHarvest;
    /// @notice Total returns that Strategy has realized for Vault
    /// @dev max strategy total gain of 79,228,162,514,264,337,593,543,950,335
    uint128 strategyTotalGain;
    /// Slot 2
    /// @notice Total outstanding debt that Strategy has
    /// @dev max total debt of 79,228,162,514,264,337,593,543,950,335
    uint128 strategyTotalDebt;
    /// @notice Total losses that Strategy has realized for Vault
    /// @dev max strategy total loss of 79,228,162,514,264,337,593,543,950,335
    uint128 strategyTotalLoss;
}
