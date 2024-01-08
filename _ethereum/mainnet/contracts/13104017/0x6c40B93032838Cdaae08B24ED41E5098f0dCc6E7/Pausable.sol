// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./PausableStore.sol";

/* INHERITANCE IMPORTS */

import "./Context.sol";
import "./PausableEvents.sol";

/* STORAGE */

import "./ERC20Storage.sol";

contract Pausable is Context, PausableEvents, ERC20Storage {

    /* MODIFIERS */

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused_(), "Pausable.whenNotPaused: PAUSED");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused_(), "Pausable.whenPaused: NOT_PAUSED");
        _;
    }
    
    /* INITIALIZE METHOD */

    /**
     * @dev Sets the value for {isPaused} to false once during initialization. 
     * It is the developer's responsibility to only call this 
     * function in initialize() of the base contract context.
     */
    function _initializePausable() internal {
        x.pausable.isPaused = false;
    }

    /* GETTER METHODS */

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function _paused() internal view returns (bool) {
        return _paused_();
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal whenNotPaused {
        x.pausable.isPaused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal whenPaused {
        x.pausable.isPaused = false;
        emit Unpaused(_msgSender());
    }

    /* PRIVATE LOGIC METHODS */ 

    function _paused_() private view returns (bool) {
        return x.pausable.isPaused;
    }
}