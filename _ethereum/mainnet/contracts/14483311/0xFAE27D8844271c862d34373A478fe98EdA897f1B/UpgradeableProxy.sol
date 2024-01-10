/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "TransparentUpgradeableProxy.sol";
import "Ownable.sol";

contract UpgradeableProxy is TransparentUpgradeableProxy, Ownable {
    constructor(address _logic, address admin_, bytes memory data) TransparentUpgradeableProxy(_logic, admin_, data) Ownable() {}
}