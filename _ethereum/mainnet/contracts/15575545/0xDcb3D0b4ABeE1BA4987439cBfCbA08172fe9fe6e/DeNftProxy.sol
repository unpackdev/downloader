// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BeaconProxy.sol";

contract DeNftProxy is BeaconProxy {
    constructor(address beacon, bytes memory data) BeaconProxy(beacon, data) {

    }
}
