// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./AccessControl.sol";

/**
 * @notice Implements functions to add  role-based access control mechanisms.
 */
contract MixinAccessControl is AccessControl {
    error CallerNotOperator();
    error NotAllowedAccess(bytes32 role, address account);

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyOperator() {
        if (!hasRole(OPERATOR_ROLE, msg.sender)) revert CallerNotOperator();
        _;
    }

    /**
     * @dev Initializes the roles.
     * @param _admin The address of the admin role
     */
    function _setupInitialRoles(address _admin) internal {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, _admin);
    }

    /**
     * @notice Adds a new admin as Operator
     * @param admin The address of the new admin
     */
    function addOperator(address admin) external {
        super.grantRole(OPERATOR_ROLE, admin);
    }

    /**
     * @notice Removes an admin as Operator
     * @param admin The address of the admin to remove
     */
    function removeOperator(address admin) external {
        revokeRole(OPERATOR_ROLE, admin);
    }

    /**
     * @dev Revokes `role` from `account`.
     * @param role The role to be revoked
     * @param account The address of the account to revoke the role from
     */
    function revokeRole(bytes32 role, address account) public override {
        if (account == msg.sender) revert NotAllowedAccess(role, account);

        super.revokeRole(role, account);
    }

    /**
     * @notice Revokes `role` from the calling account. This function is disabled by overriding it with a revert.
     * @param role The role to be revoked
     * @param account The address of the account to revoke the role from
     */
    function renounceRole(bytes32 role, address account) public pure override {
        revert NotAllowedAccess(role, account);
    }
}
