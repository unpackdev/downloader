// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import "./IVersioned.sol";

import "./IAccessControlEnumerableUpgradeable.sol";

/**
 * @dev this is the common interface for upgradeable contracts
 */
interface IUpgradeable is IAccessControlEnumerableUpgradeable, IVersioned {

}
