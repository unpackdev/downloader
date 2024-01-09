// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IEligibility {

//    function getGate(uint) external view returns (struct Gate)
//    function addGate(uint...) external

    function isEligible(uint, address, bytes32[] memory) external view returns (bool eligible);

    function passThruGate(uint, address, bytes32[] memory) external;
}
