// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./UpgradeableBeacon.sol";

/**
 * Beacon contract which contains the xAssetCLR implementation address
 * Deployed only once
 * Used by xAssetCLRProxy to determine implementation address
 */
contract xAssetCLRBeacon is UpgradeableBeacon {
    constructor(address _implementation) UpgradeableBeacon(_implementation) {}
}
