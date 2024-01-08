// SPDX-License-Identifier: MIT

/******************************************************************************\
* (https://github.com/shroomtopia)
* Implementation of ShroomTopia's ERC20 SPOR Proxy
/******************************************************************************/

pragma solidity ^0.8.3;

import "./TransparentUpgradeableProxy.sol";

contract SPORProxy is TransparentUpgradeableProxy {
  constructor(address _logic, address admin_) TransparentUpgradeableProxy(_logic, admin_, "") {}
}
