// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";

contract Potus45Proxy is TransparentUpgradeableProxy {

    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) public {
    }

}