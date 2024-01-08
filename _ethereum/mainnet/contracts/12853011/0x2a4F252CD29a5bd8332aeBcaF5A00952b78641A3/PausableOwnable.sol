// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

/**
 * @title PausableOwnable
 *
 * @dev Contract provides a stop emergency mechanism for owner.
 */
abstract contract PausableOwnable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    /**
     * @dev Allows the owner to pause, triggers stopped state.
     *
     * Emits a {Paused} event.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Allows the owner to do unpause, returns to normal state.
     *
     * Emits a {Unpaused} event.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}
