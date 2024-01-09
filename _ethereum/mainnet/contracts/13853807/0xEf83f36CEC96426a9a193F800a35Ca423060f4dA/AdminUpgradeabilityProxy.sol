// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./TransparentUpgradeableProxy.sol";

contract AdminUpgradeabilityProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) payable TransparentUpgradeableProxy(logic, admin, data) {}
}