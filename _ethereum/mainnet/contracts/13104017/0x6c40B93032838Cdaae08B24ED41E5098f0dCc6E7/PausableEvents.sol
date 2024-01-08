// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface PausableEvents {

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

}