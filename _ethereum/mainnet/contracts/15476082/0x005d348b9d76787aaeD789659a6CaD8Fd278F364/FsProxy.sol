//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./TransparentUpgradeableProxy.sol";

contract FsProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, admin_, _data) {}
}
