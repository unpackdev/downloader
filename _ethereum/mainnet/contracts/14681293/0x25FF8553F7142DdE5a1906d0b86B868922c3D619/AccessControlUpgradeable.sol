// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./Initializable.sol";

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
 * By default, the admin role for all roles is `DEPLOYER_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEPLOYER_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }

    mapping(bytes32 => mapping(address => bool)) private _roles;

    bytes32 public constant DEPLOYER_ROLE = 0x00;
    bytes32 public constant PYT_ADMIN_ROLE = keccak256("PYT_ADMIN_ROLE");
    bytes32 public constant LAND_OWNER_ROLE = keccak256("LAND_OWNER_ROLE");

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role][account];
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev Public function grant land owner role
     * Can be called only by addresses with PYT Admin or Default Admin Role
     */
    function grantLandOwnerRole(address account) public {
        require(hasRole(PYT_ADMIN_ROLE, _msgSender()) || hasRole(DEPLOYER_ROLE, _msgSender()), 'Access Control: You do not have the required role for this function');

        _grantRole(LAND_OWNER_ROLE, account);
    }

    /**
     * @dev Public function revoke land owner role
     * Can be called only by addresses with PYT Admin or Default Admin Role
     */
    function revokeLandOwnerRole(address account) public {
        require(hasRole(PYT_ADMIN_ROLE, _msgSender()) || hasRole(DEPLOYER_ROLE, _msgSender()), 'Access Control: You do not have the required role for this function');

        _revokeRole(LAND_OWNER_ROLE, account);
    }

    /**
     * @dev Public function grant pyt admin role
     * Can be called only by addresses with Default Admin Role
     */
    function grantPYTAdminRole(address account) public {
        require(hasRole(DEPLOYER_ROLE, _msgSender()), 'Access Control: You do not have the required role for this function');

        _grantRole(PYT_ADMIN_ROLE, account);
    }

    /**
     * @dev Public function revoke pyt admin role
     * Can be called only by addresses with Default Admin Role
     */
    function revokePYTAdminRole(address account) public {
        require(hasRole(DEPLOYER_ROLE, _msgSender()), 'Access Control: You do not have the required role for this function');

        _revokeRole(PYT_ADMIN_ROLE, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
