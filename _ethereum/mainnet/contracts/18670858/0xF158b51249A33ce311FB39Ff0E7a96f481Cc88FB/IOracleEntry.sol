// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface IOracleEntry {
    enum DataSource {
        None,
        Pyth
    }

    event DataSourceAdapterSet(DataSource dataSource, address adapter);

    /// @notice Gets `asset` price at `timestamp` in terms of USD using `dataSource`
    function getSinglePrice(
        address asset,
        uint40 timestamp,
        DataSource dataSource
    ) external view returns (uint128);

    /// @notice Gets `baseAsset` price at `timestamp` in terms of `quoteAsset` using `dataSource`
    function getPrice(
        address baseAsset,
        address quoteAsset,
        uint40 timestamp,
        DataSource dataSource
    ) external view returns (uint128);

    /// @notice Sets data source adapter
    function setDataSourceAdapter(
        DataSource dataSource,
        address adapter
    ) external;

    function getTargetDecimals() external pure returns (uint8);
}
