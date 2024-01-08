// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./BEP20.sol";

/**
 * @dev BEP20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract BEP20Pausable is BEP20 {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Pause();

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpause();

    bool private paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
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
        require(paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state, called by the owner to pause.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused virtual override returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused virtual override returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public whenNotPaused virtual override returns (bool) {
        return super.approve(spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused virtual override returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused virtual override returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}
