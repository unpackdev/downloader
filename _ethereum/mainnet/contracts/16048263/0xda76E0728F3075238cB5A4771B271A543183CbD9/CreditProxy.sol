// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TransparentUpgradeableProxy.sol";
import "./ProxyAdmin.sol";

contract CreditProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) payable TransparentUpgradeableProxy(logic, admin, data) {}
}
