// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPointsDistributor {
    struct Shortcut {        
        uint256 complexity;
        bool isActive;
    }

    function distributePoints(uint256 amount) external;

    function shortcuts(address) external returns (Shortcut memory);
    function feeDestination() external returns(address);
    function isPointDistributionActive() external returns(bool);
}
