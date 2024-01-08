// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
library RoleBasedAccessControlLib {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    struct RoleBasedAccessControlStorage {
        mapping (bytes32 => RoleData) _roles;
        mapping (bytes32 => EnumerableSet.AddressSet) _roleMembers;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || interfaceId == type(IAccessControlEnumerable).interfaceId;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasRole(RoleBasedAccessControlStorage storage s, bytes32 role, address account) internal view returns (bool) {
        return s._roles[role].members[account];
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(RoleBasedAccessControlStorage storage s, bytes32 role, address account) external view returns (bool) {
        return _hasRole(s, role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function _getRoleAdmin(RoleBasedAccessControlStorage storage s, bytes32 role) internal view returns (bytes32) {
        return s._roles[role].adminRole;
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(RoleBasedAccessControlStorage storage s, bytes32 role) external view returns (bytes32) {
        return _getRoleAdmin(s, role);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(RoleBasedAccessControlStorage storage s, bytes32 role, address account) external {
        require(_hasRole(s, _getRoleAdmin(s, role), msg.sender), "AccessControl: must be admin");

        _grantRole(s, role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(RoleBasedAccessControlStorage storage s, bytes32 role, address account) external {
        require(_hasRole(s, _getRoleAdmin(s, role), msg.sender), "AccessControl: must be admin");

        _revokeRole(s, role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(RoleBasedAccessControlStorage storage s, bytes32 role, address account) external {
        require(account == msg.sender, "Can only renounce role for self");

        _revokeRole(s, role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(RoleBasedAccessControlStorage storage s, bytes32 role, address account) external {
        _grantRole(s, role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(RoleBasedAccessControlStorage storage s, bytes32 role, bytes32 adminRole) internal {
        emit RoleAdminChanged(role, _getRoleAdmin(s, role), adminRole);
        s._roles[role].adminRole = adminRole;
    }

    function _grantRole(RoleBasedAccessControlStorage storage s, bytes32 role, address account) private {
        if (!_hasRole(s, role, account)) {
            s._roles[role].members[account] = true;
            s._roleMembers[role].add(account);
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(RoleBasedAccessControlStorage storage s, bytes32 role, address account) private {
        require(role != DEFAULT_ADMIN_ROLE || account != msg.sender, "Cannot revoke own admin role");
        if (_hasRole(s, role, account)) {
            s._roles[role].members[account] = false;
            s._roleMembers[role].remove(account);
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    // Enumerable extension; the rest has been merged in to _grant and _revoke

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(RoleBasedAccessControlStorage storage s, bytes32 role, uint256 index) external view returns (address) {
        return s._roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(RoleBasedAccessControlStorage storage s, bytes32 role) external view returns (uint256) {
        return s._roleMembers[role].length();
    }


}
