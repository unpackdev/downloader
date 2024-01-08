// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./TransparentUpgradeableProxy.sol";

contract CitadelV2Proxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) {}
}