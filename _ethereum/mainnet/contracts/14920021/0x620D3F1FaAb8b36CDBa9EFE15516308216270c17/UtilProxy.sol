// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import "TransparentUpgradeableProxy.sol";

contract UtilProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, admin_, _data) {}
}
