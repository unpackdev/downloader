// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./TransparentUpgradeableProxy.sol";

contract GDEXProxy is TransparentUpgradeableProxy {

    constructor(
      address _logic,
      address _proxyAdmin
    ) public payable TransparentUpgradeableProxy(_logic, _proxyAdmin, "") {}

}
