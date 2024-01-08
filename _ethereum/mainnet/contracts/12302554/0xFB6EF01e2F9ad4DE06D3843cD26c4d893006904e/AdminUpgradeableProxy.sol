// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./TransparentUpgradeableProxy.sol";

/**
 * @dev TransparentUpgradeableProxy where admin is allowed to call implementation methods.
 */
contract AdminUpgradeableProxy is TransparentUpgradeableProxy {
  /**
   * @dev Initializes an upgradeable proxy backed by the implementation at `_logic`.
   */
  constructor(
    address _logic,
    address _admin,
    bytes memory _data
  ) public payable TransparentUpgradeableProxy(_logic, _admin, _data) {}
}
