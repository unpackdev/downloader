// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

contract BeaconStorage {
    /// @notice Holds the address of the upgrade beacon
    address internal immutable beacon;

    constructor(address beacon_) {
        beacon = beacon_;
    }
}
