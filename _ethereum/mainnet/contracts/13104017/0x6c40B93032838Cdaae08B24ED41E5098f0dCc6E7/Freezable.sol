// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./FreezableStore.sol";

/* INHERITANCE IMPORTS */

import "./Context.sol";
import "./FreezableEvents.sol";

/* STORAGE */

import "./ERC20Storage.sol";

contract Freezable is Context, FreezableEvents, ERC20Storage {

    /* MODIFIERS */

    /**
     * @dev Modifier to make a function callable only when an account is not frozen.
     *
     * Requirements:
     *
     * - `account` must not be frozen.
     */
    modifier whenNotFrozen(address account) {
        require(
            !_frozen_(account),
            "Freezable.whenNotFrozen: FROZEN"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the `account` is frozen.
     *
     * Requirements:
     *
     * - `account` must be frozen.
     */
    modifier whenFrozen(address account) {
        require(
            _frozen_(account),
            "Freezable.whenFrozen: NOT_FROZEN"
        );
        _;
    }

    /* GETTER METHODS */

    /**
     * @dev Returns true if `account` is frozen, and false otherwise.
     */
    function _frozen(address account) internal view returns (bool) {
        return _frozen_(account);
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev Triggers stopped `account` state.
     *
     * Requirements:
     *
     * - `account` must not be frozen.
     */
    function _freeze(address account) internal whenNotFrozen(account) {
        require(account != address(0), "Freezable._freeze: ACCOUNT_ZERO_ADDRESS");
        x.freezable.isFrozen[account] = true;
        emit Frozen(_msgSender(), account);
    }

    /**
     * @dev Returns `account` to normal state.
     *
     * Requirements:
     *
     * - `account` must be frozen.
     */
    function _unfreeze(address account) internal whenFrozen(account) {
        x.freezable.isFrozen[account] = false;
        emit Unfrozen(_msgSender(), account);
    }

    /* PRIVATE LOGIC METHODS */

    function _frozen_(address account) private view returns (bool) {
        return x.freezable.isFrozen[account];
    }
}