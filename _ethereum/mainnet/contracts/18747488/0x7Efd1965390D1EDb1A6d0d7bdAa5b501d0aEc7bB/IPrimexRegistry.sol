// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IPrimexRegistry {
    /**
     * @notice A mapping that stores whether a role is designated for contracts only.
     * @param role The bytes32 identifier of the role.
     * @return True if the role is designated for contracts only
     */
    function isRoleForContractsOnly(bytes32 role) external view returns (bool);

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Sets roles to be restricted for contracts only.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param roles An array of bytes32 role identifiers to be restricted for contracts only.
     */
    function setRolesForContractsOnly(bytes32[] calldata roles) external;

    /**
     * @notice Removes roles to be restricted for contracts only.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param roles An array of bytes32 role identifiers to be removed.
     */
    function removeRolesForContractsOnly(bytes32[] calldata roles) external;

    function grantRole(bytes32 role, address account) external;
}
