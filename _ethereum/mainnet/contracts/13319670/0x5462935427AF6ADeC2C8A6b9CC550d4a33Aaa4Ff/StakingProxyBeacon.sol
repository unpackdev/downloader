// SPDX-License-Identifier: ISC

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./UpgradeableBeacon.sol";

contract StakingProxyBeacon is UpgradeableBeacon {
    constructor(address _implementation) public UpgradeableBeacon(_implementation) {}
}
