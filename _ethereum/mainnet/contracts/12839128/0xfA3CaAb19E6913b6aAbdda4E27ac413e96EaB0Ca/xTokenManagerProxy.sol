//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";

contract xTokenManagerProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _proxyAdmin)
        TransparentUpgradeableProxy(_logic, _proxyAdmin, "")
    {}
}