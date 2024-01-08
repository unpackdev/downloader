// SPDX-License-Identifier: ISC

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BeaconProxy.sol";

contract StakingProxyProxy is BeaconProxy {
    constructor(address _beacon) public BeaconProxy(_beacon, "") {}
}
