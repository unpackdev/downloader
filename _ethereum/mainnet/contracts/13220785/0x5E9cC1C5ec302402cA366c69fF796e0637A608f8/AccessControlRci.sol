pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

import "./AccessControl.sol";

abstract contract AccessControlRci is AccessControl{
    bytes32 public constant RCI_MAIN_ADMIN = keccak256('RCI_MAIN_ADMIN');
    bytes32 public constant RCI_CHILD_ADMIN = keccak256('RCI_CHILD_ADMIN');

    modifier onlyMainAdmin()
    {
        require(hasRole(RCI_MAIN_ADMIN, msg.sender), "Caller is unauthorized.");
        _;
    }

    modifier onlyAdmin()
    {
        require(hasRole(RCI_CHILD_ADMIN, msg.sender), "Caller is unauthorized.");
        _;
    }

    function _initializeRciAdmin()
    internal
    {
        _setupRole(RCI_MAIN_ADMIN, msg.sender);
        _setRoleAdmin(RCI_MAIN_ADMIN, RCI_MAIN_ADMIN);

        _setupRole(RCI_CHILD_ADMIN, msg.sender);
        _setRoleAdmin(RCI_CHILD_ADMIN, RCI_MAIN_ADMIN);
    }
}
