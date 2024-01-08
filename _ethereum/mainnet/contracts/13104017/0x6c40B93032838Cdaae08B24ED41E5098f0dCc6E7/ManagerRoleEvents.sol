// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ManagerRoleEvents {

    /**
     * @dev Emitted when `account` is assigned the manager Role.
     */
    event ManagerAdded(address indexed account);
    
    /**
     * @dev Emitted when `account` has renounced its manager Role.
     */
    event ManagerRemoved(address indexed account);
    
}