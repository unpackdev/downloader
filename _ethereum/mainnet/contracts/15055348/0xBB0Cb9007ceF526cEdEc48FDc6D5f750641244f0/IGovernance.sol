// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IGovernance {
    function notifyAccVolumeUpdated(uint checkpoint, uint accVolumeX2) external;
}
