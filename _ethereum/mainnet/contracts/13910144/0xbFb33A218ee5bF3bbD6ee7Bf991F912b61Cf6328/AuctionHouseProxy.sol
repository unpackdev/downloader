// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./TransparentUpgradeableProxy.sol";

contract AuctionHouseProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) TransparentUpgradeableProxy(logic, admin, data) {}
}
