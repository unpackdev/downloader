// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./RolesAuthority.sol";

contract QuantumAuthority is RolesAuthority {

    constructor(address owner) RolesAuthority(owner, Authority(address(0))) {}

	/// @notice For multiples users, set the status of a role
    /// @dev the role has to belong to the Roles enum
    /// @param users users
    /// @param role role
    /// @param enabled to enable or not
    function setMultipleUsers(address[] calldata users, uint8 role, bool enabled) public requiresAuth {
        for(uint i = 0; i < users.length; i++) {
            setUserRole(users[i], role, enabled);
        }
    }

	/// @notice For one role, define an array of capabilities (functions it can call)
    /// @dev the role has to belong to the Roles enum
    /// @param target address of contract whose functions will be used
    /// @param role role
    /// @param functionSigs signatures of functions (4 bytes)
    /// @param enabled to enable or not
    function setRoleWithMultipleCapability(address target, uint8 role, bytes4[] calldata functionSigs, bool enabled) public requiresAuth {
        for(uint i = 0; i < functionSigs.length; i++) {
            setRoleCapability(role, target, functionSigs[i], enabled);
        }
    }
}