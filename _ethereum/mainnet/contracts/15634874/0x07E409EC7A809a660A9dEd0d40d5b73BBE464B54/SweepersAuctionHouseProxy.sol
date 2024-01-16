// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./TransparentUpgradeableProxy.sol";

contract SweepersAuctionHouseProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) TransparentUpgradeableProxy(logic, admin, data) {}
}
