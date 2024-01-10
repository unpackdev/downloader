//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IOracle{
    function getTimestampCountById(bytes32 _queryId)
        external
        view
        returns (uint256);
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);
}