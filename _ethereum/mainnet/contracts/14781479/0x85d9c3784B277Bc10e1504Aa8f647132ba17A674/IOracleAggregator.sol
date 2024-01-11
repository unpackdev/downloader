// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

interface IOracleAggregator {
    function __callback(uint256 timestamp, uint256 data) external;

    function getData(address oracleId, uint256 timestamp) external view returns (uint256 dataResult);

    function hasData(address oracleId, uint256 timestamp) external view returns (bool);
}
