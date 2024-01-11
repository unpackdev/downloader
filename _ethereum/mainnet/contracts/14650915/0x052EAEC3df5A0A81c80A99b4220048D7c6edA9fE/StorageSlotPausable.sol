// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./StorageSlot.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 */
abstract contract StorageSlotPausable is Context {
    bytes32 private constant _PAUSED_SLOT = bytes32(uint256(keccak256("StorageSlotPausable.paused")) - 1);

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Returns the current owner.
     */
    function _getPaused() private view returns (bool) {
        return StorageSlot.getBooleanSlot(_PAUSED_SLOT).value;
    }

    /**
     * @dev Stores a new address in the owner slot.
     */
    function _setPaused(bool value) private {
        StorageSlot.getBooleanSlot(_PAUSED_SLOT).value = value;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _getPaused();
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "StorageSlotPausable: paused");
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
        require(paused(), "StorageSlotPausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _setPaused(true);
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _setPaused(false);
        emit Unpaused(_msgSender());
    }
}
