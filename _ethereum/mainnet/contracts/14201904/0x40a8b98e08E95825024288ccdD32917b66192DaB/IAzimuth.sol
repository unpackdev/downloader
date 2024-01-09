// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAzimuth {
    function canVoteAs(uint32, address) view external returns (bool);
    function canTransfer(uint32, address) view external returns (bool);
    function getPointSize(uint32) external pure returns (Size);
    function owner() external returns (address);
    function getSpawnProxy(uint32) view external returns (address);
    enum Size
    {
        Galaxy, // = 0
        Star,   // = 1
        Planet  // = 2
    }
}
