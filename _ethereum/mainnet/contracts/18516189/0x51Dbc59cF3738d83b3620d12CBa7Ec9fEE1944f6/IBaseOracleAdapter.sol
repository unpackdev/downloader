// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IBaseOracleAdapter {
    function tryLatestDataAt(uint256 _timestamp, uint256 _maxTraversal)
        external
        view
        returns (int256 answer, uint256 timestamp);

    function getLatestSourceData() external view returns (int256 answer, uint256 timestamp);
}
