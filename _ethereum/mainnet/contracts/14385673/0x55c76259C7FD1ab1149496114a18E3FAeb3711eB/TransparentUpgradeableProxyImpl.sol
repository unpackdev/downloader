// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "TransparentUpgradeableProxy.sol";

contract TransparentUpgradeableProxyImpl is TransparentUpgradeableProxy {
  constructor(
    address _logic,
    address _admin,
    bytes memory _data
  ) payable TransparentUpgradeableProxy(_logic, _admin, _data) {}
}
