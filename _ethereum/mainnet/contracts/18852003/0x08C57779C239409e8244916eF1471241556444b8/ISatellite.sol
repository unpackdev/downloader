// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISatellite {
    function isBroadcasting() external view returns (bool);

    function capture(uint256) external;

    function getBroadcast(uint256) external view returns (string memory);
}
