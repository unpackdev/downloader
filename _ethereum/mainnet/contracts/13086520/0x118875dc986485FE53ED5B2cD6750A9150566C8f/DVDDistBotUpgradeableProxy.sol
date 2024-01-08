// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "./TransparentUpgradeableProxy.sol";

contract DVDDistBotUpgradeableProxy is TransparentUpgradeableProxy {

    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) public {
    }

}