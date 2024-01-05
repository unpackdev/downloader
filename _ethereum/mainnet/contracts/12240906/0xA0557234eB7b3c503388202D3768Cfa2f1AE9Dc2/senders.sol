// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./TransparentUpgradeableProxy.sol";

contract InstaAaveV2MigratorSender is TransparentUpgradeableProxy {
    constructor(address _logic, address admin_, bytes memory _data) public TransparentUpgradeableProxy(_logic, admin_, _data) {}
}