// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";

contract WstTAOProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address admin, bytes memory _data)
        TransparentUpgradeableProxy(_logic, admin, _data) {}
}