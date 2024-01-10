// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.6.0 <0.7.0;

import "./TransparentUpgradeableProxy.sol";

/// @title A proxy contract for did
contract EternalStorageProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) public payable TransparentUpgradeableProxy(_logic, admin_, _data) {}
}
