// SPDX-License-Identifier: Private
pragma solidity ^0.8.20;

import "./EnumerableSet.sol";
import "./IFreezable.sol";

abstract contract Freezable is IFreezable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _freezedAccounts;

    constructor() {}

    /**
     * @dev Modifier to make a function callable only when the address is not freezed.
     *
     * Requirements:
     *
     * @param target Check if address is not freezed
     */
    modifier whenNotFreezed(address target) {
        _requireNotFreezed(target);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the address is freezed.
     *
     * Requirements:
     *
     * @param target Check if address is freezed
     */
    modifier whenFreezed(address target) {
        _requireFreezed(target);
        _;
    }

    /**
     * @dev Returns true if the address is freezed, and false otherwise.
     *
     * Requirements:
     *
     *  @param target The verified address
     */
    function freezed(address target) public view virtual returns (bool) {
        return _freezedAccounts.contains(target);
    }

    /**
     * @dev Throws if the address is freezed.
     *
     * Requirements:
     *
     * @param target Address should not to be freezed
     */
    function _requireNotFreezed(address target) internal view virtual {
        if (freezed(target)) {
            revert EnforcedFreeze(target);
        }
    }

    /**
     * @dev Throws if the address is not freezed.
     *
     * Requirements:
     *
     *  @param target Address should to be freezed
     */
    function _requireFreezed(address target) internal view virtual {
        if (!freezed(target)) {
            revert ExpectedFreeze(target);
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     *   @param target Address need to be freezed
     */
    function _freeze(address target) internal virtual whenNotFreezed(target) {
        _freezedAccounts.add(target);
        emit Freezed(target);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     *  @param target Address need to be unfreezed
     */
    function _unfreeze(address target) internal virtual whenFreezed(target) {
        _freezedAccounts.remove(target);
        emit Unfreezed(target);
    }
}
