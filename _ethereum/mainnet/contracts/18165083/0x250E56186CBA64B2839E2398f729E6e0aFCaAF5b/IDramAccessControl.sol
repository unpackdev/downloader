// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDramAccessControl {
    /**
     * @dev The `account` is missing a `role`.
     */
    error MissingRoleError(bytes32 role, address account);

    /**
     * @dev Happens when a caller wants to renounce a role from another address.
     */
    error NotSelfError();

    /**
     * @dev Happens when updating the ADMIN_ROLE directly.
     */
    error DirectAdminUpdateError();

    /**
     * @dev Happens when the acceptAdminRoleTransfer gets called when there is no
     * pending admin.
     */
    error NotPendingAdminError();

    /**
     * @dev Happens if new admin address is either zero or the msg.sender
     */
    error InvalidAdminTransferError();

    /**
     * @notice Gets emitted when an account gets a role.
     * @param role Granted role
     * @param account Address with the role
     * @param sender Operator who granted the role
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Gets emitted when a role is revoke from an account.
     * @param role Revoked role
     * @param account Address which had the role
     * @param sender Operator who revoked the role
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Happens when the admin role transfer process gets finalized.
     * @param previousAdmin The account that had the ADMIN_ROLE
     * @param newAdmin The account that has the ADMIN_ROLE
     */
    event AdminRoleTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    /**
     * @notice Returns a boolean indicating if the account has the requested role.
     * @param role Role to check
     * @param account Address that needs to be checked wether it has the role or not
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /**
     * @notice Grants one of the defined roles to an account.
     * NOTE: Can't use for admin role management!
     * @dev Protected by onlyRoleOrAdmin modifier.
     * @param role The role to be granted
     * @param account Address that will have the role
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @notice Revokes one of the defined roles from an account.
     * NOTE: Can't use for admin role management!
     * @dev Protected by onlyRoleOrAdmin modifier.
     * @param role The role to be revoked
     * @param account Address that won't have the role anymore
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @notice Renounces one of the defined roles from an account.
     * An account with a role can call this to renounce the role from its address.
     * NOTE: Can't use for admin role management!
     * @dev the account should be the msg.sender.
     * @param role The role to be renounced
     * @param account The caller address that will renounce the role from itself
     */
    function renounceRole(bytes32 role, address account) external;

    /**
     * @notice Transfers admin role to another account.
     * NOTE: Only the one with admin role is able to call this function.
     * This function starts transferring admin to a new address and will be finalized
     * when acceptAdminRoleTransfer is called by the new admin account.
     * @dev Protected by onlyRole so that only admin can call this function.
     * @param newAdmin The address of the new admin
     */
    function transferAdminRole(address newAdmin) external;

    /**
     * @notice Accepts admin role to from account.
     * Only works when there is a pending admin.
     * This function ends transferring admin to a new address process.
     */
    function acceptAdminRoleTransfer() external;

    /**
     * @notice Returns current admin and the pending admin addresses.
     */
    function getAdminRoleTransferInfo()
        external
        view
        returns (address, address);

    /**
     * @notice If admin transferring process is either started by mistake or needed to be
     * cancelled, the current admin should call this function.
     * @dev Protected by onlyRole so that only admin can call this function.
     */
    function cancelAdminTransfer() external;
}
