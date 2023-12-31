// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";

contract RolesFacet is AccessControl {

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external {
        _setRoleAdmin(role, adminRole);
    }

    function checkRole(bytes32 role) external view {
        _checkRole(role);
    }

    function checkRole(bytes32 role, address account) external view {
        _checkRole(role, account);
    }

}