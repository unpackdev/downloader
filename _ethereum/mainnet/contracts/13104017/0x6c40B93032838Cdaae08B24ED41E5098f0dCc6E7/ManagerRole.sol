// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./ManagerRoleStore.sol";

/* LIBRARY IMPORTS */

import "./Roles.sol";

/* INHERITANCE IMPORTS */

import "./Context.sol";
import "./ManagerRoleEvents.sol";

/* STORAGE */

import "./ERC20Storage.sol"; 

contract ManagerRole is Context, ManagerRoleEvents, ERC20Storage {
    /* LIBRARY USAGE */
    
    using Roles for Role;

    /* MODIFIERS */

    modifier onlyUninitialized() {
        require(!x.managerRole.initialized, "ManagerRole.onlyUninitialized: ALREADY_INITIALIZED");
        _;
    }

    modifier onlyInitialized() {
        require(x.managerRole.initialized, "ManagerRole.onlyInitialized: NOT_INITIALIZED");
        _;
    }

    modifier onlyManager() {
        require(_isManager(_msgSender()), "ManagerRole.onlyManager: NOT_MANAGER");
        _;
    }

    /* INITIALIZE METHOD */
    
    /**
     * @dev Gives the intialize() caller the manager role during initialization. 
     * It is the developer's responsibility to only call this 
     * function in initialize() of the base contract context.
     */
    function _initializeManagerRole(
        address account
    )
        internal
        onlyUninitialized
     {
        _addManager_(account);
        x.managerRole.initialized = true;
    }

    /* GETTER METHODS */

    /**
     * @dev Returns true if `account` has the manager role, and false otherwise.
     */
    function _isManager(
        address account
    )
        internal
        view
        returns (bool)
    {
        return _isManager_(account);
    }


    /* STATE CHANGE METHODS */
    
    /**
     * @dev Give the manager role to `account`.
     */
    function _addManager(
        address account
    )
        internal
        onlyManager
        onlyInitialized
    {
        _addManager_(account);
    }

    /**
     * @dev Renounce the manager role for the caller.
     */
    function _renounceManager()
        internal
        onlyInitialized
    {
        _removeManager_(_msgSender());
    }

    /* PRIVATE LOGIC METHODS */

    function _isManager_(
        address account
    )
        private
        view
        returns (bool)
    {
        return x.managerRole.managers._has(account);
    }

    function _addManager_(
        address account
    )
        private
    {
        x.managerRole.managers._add(account);
        emit ManagerAdded(account);
    }

    function _removeManager_(
        address account
    )
        private
    {
        x.managerRole.managers._safeRemove(account);
        emit ManagerRemoved(account);
    }
}