// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered.
     */
    event Pause(uint256 sinceBlock);

    uint256 private _pausedSinceBlock;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor(uint256 sinceBlock) {
        //_pausedSinceBlock = ~uint256(0);
        _pause(sinceBlock);
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function isPaused() public view virtual returns (bool) {
        return _pausedSinceBlock <= block.number;
    }

    /**
     * @dev Returns block number since which the contract is paused.
     */
    function pausedSinceBlock() public view virtual returns (uint256) {
        return _pausedSinceBlock;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must *NOT* be paused.
     */
    modifier requireNotPaused() {
        require(!isPaused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier requirePaused() {
        require(isPaused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Sets block since which the contract is paused.
     */
    function _pause(uint256 sinceBlock) internal {
        _pausedSinceBlock = sinceBlock < block.number ? block.number : sinceBlock;
        emit Pause(_pausedSinceBlock);
    }

    /**
     * @dev Unpauses contract.
     */
    function _unpause() internal {
        _pause(~uint256(0));
    }
}
