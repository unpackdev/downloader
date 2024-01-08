// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* STORAGE LAYOUT */

struct InitializableStore {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool initializing;
}