//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./TransparentUpgradeableProxy.sol";

contract MockxTokenManagerProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _proxyAdmin) public TransparentUpgradeableProxy(_logic, _proxyAdmin, "") {}
}
