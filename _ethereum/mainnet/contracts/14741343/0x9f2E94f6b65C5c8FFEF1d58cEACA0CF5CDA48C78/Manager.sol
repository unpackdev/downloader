// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./AccessControl.sol";
import "./IManager.sol";

contract Manager is AccessControl, IManager {
    // keccak256("SUPER_ADMIN")
    bytes32 public constant SUPER_ADMIN = 0xd980155b32cf66e6af51e0972d64b9d5efe0e6f237dfaa4bdc83f990dd79e9c8;
    // keccak256("ADMIN")
    bytes32 public constant ADMIN = 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42;
    // keccak256("GOVERNANCE")
    bytes32 public constant GOVERNANCE = 0x35a7846a2a701fff6f9d61a46ebff5da578c5dcee8bdf361c569f9ea4ee64771;

    // a
    constructor(address[] memory _admins) {
        for (uint256 i = 0; i < _admins.length; ++i) {
            _setupRole(ADMIN, _admins[i]);
        }
        _setRoleAdmin(ADMIN, SUPER_ADMIN);
        _setRoleAdmin(GOVERNANCE, SUPER_ADMIN);
        _setupRole(SUPER_ADMIN, msg.sender);
    }

    // super admin function
    function transferSuperAdmin(address _newSuperAdmin) public onlyRole(SUPER_ADMIN) {
        require(_newSuperAdmin != address(0) && _newSuperAdmin != msg.sender, "Invalid new super admin");
        renounceRole(SUPER_ADMIN, msg.sender);
        _setupRole(SUPER_ADMIN, _newSuperAdmin);
    }

    function isAdmin(address _user) public view override returns (bool) {
        return hasRole(ADMIN, _user);
    }

    function isGorvernance(address _user) public view override returns (bool) {
        return hasRole(GOVERNANCE, _user);
    }
}
