// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface FreezableEvents {
    
    /**
     * @dev Emitted when `account` is frozen by `manager`.
     */
    event Frozen(address manager, address account);

    /**
     * @dev Emitted when `account` is unfrozen by `manager`.
     */
    event Unfrozen(address manager, address account);

}