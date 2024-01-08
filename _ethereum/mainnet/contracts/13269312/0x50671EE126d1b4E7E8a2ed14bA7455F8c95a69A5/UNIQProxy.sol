//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./TransparentUpgradeableProxy.sol";

contract UniqProxy is TransparentUpgradeableProxy{
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}
}