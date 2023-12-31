// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IVersioned.sol";

import "./IAccessControlEnumerableUpgradeable.sol";

/**
 * @dev this is the common interface for upgradeable contracts
 */
interface IUpgradeable is IAccessControlEnumerableUpgradeable, IVersioned {

}
