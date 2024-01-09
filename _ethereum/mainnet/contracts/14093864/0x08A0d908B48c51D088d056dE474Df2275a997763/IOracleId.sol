// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IOracleId {
    function _callback(uint256 endTime) external;
    function getResult() external view returns(uint256);
    function oracleAggregator() external view returns(address);
}
