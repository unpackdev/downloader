// SPDX-License-Identifier: GPL-3.0

/// @title The YQC DAO auction house proxy

pragma solidity ^0.8.6;

import "./TransparentUpgradeableProxy.sol";

contract YQCAuctionHouseProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) TransparentUpgradeableProxy(logic, admin, data) {}
}
