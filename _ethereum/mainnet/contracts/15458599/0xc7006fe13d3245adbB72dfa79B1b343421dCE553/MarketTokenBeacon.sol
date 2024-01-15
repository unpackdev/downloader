// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./UpgradeableBeacon.sol";

contract MarketTokenBeacon is UpgradeableBeacon {
    constructor(address impl) UpgradeableBeacon(impl) {}
}
