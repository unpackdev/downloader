// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./BeaconProxy.sol";

/**
 * Proxy contract containing storage of xAssetCLR instance
 * Needs xAssetCLRBeacon to be deployed to work
 * Reads xAssetCLR implementation address from beacon and delegates to it
 */
contract xAssetCLRProxy is BeaconProxy {
    constructor(address _beacon)
        BeaconProxy(_beacon, "")
    {}
}
