// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IAllowlist {
    // Getters
    function allowlist(address) external returns (bool);

    function remainingSeats() external returns (uint256);

    function deadline() external returns (uint256);

    // ------------------
    // Public write functions
    // ------------------

    function addAddressToAllowlist(address _addr) external;

    function removeSelfFromAllowlist() external;

    // ------------------
    // Function for the owner
    // ------------------

    function addSeats(uint256 _seatsToAdd) external;

    function reduceSeats(uint256 _seatsToSubstract) external;

    function setDeadline(uint256 _newDeadline) external;

    function addAddressesToAllowlist(address[] calldata _addrs) external;
}
