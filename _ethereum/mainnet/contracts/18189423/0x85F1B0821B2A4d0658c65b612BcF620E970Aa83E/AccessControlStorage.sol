// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./EnumerableSet.sol";

library AccessControlStorage {

    using EnumerableSet for EnumerableSet.AddressSet;

    error NotRoleAuthorizedError(bytes32, address user);

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant MANAGER_ROLE = keccak256('contracts.role.0xManager');

    bytes32 internal constant STORAGE_SLOT = keccak256('contracts.storage.AccessControl');

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function setContractOwner(address account) internal {
        layout().roles[DEFAULT_ADMIN_ROLE].members.add(account);
        emit RoleGranted(DEFAULT_ADMIN_ROLE, account, msg.sender);
    }

    function enforceIsOwner() internal view {
        if (!layout().roles[DEFAULT_ADMIN_ROLE].members.contains(msg.sender)) 
            revert NotRoleAuthorizedError(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function enforceIsRole(bytes32 role) internal view {
        if (!layout().roles[role].members.contains(msg.sender)) 
            revert NotRoleAuthorizedError(role, msg.sender);
    }

    function enforceIsRole(bytes32 role, address user) internal view {
        if (!layout().roles[role].members.contains(user)) 
            revert NotRoleAuthorizedError(role, user);
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}