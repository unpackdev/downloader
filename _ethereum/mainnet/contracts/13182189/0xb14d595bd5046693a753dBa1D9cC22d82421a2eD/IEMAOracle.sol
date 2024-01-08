// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IEMAOracle {
    function updateAndQuery() external returns (bool updated, uint256 value);

    function UPDATE_INTERVAL() external view returns (uint256);

    function lastUpdateTimestamp() external view returns (uint256);
}
