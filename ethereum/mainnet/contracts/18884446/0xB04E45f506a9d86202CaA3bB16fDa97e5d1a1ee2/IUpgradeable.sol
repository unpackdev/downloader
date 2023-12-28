// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IVersioned.sol";

import "./IAccessControlEnumerableUpgradeable.sol";

/**
 * @dev this is the common interface for upgradeable contracts
 */
interface IUpgradeable is IAccessControlEnumerableUpgradeable, IVersioned {

}
