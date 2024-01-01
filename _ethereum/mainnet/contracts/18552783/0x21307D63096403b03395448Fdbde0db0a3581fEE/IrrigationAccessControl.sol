// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./LibDiamond.sol";

abstract contract IrrigationAccessControl is Initializable, AccessControlEnumerableUpgradeable {
    bytes32 public constant AUTO_IRRIGATE_ADMIN_ROLE = keccak256("AUTO_IRRIGATE_ADMIN_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function __IrrigationAccessControl_init() internal onlyInitializing onlySuperAdminRole {
        __AccessControlEnumerable_init_unchained();
        __IrrigationAccessControl_init_unchained();
    }

    function __IrrigationAccessControl_init_unchained() internal onlyInitializing {
        address superAdmin = _msgSender();
        // this sets the default admin for every ROLE created
        _grantRole(DEFAULT_ADMIN_ROLE, superAdmin);
        // set SuperAdmin as ADMIN_ROLE also, no need to setRoleAdmin() as it will use DEFAULT_ADMIN_ROLE
        _grantRole(ADMIN_ROLE, superAdmin);
        // all non-superAdmin can also grant/revoke roles of IRRIGATION_ADMIN_ROLE
        _setRoleAdmin(AUTO_IRRIGATE_ADMIN_ROLE, ADMIN_ROLE);
        // make superAdmin have the IRRIGATION_ADMIN_ROLE too.
        _grantRole(AUTO_IRRIGATE_ADMIN_ROLE, superAdmin);
    }

    function grantRole(
        bytes32 role,
        address account
    ) public override(IAccessControlUpgradeable, AccessControlUpgradeable) {
        // this checks the admin role that can do this.
        super.grantRole(role, account);
    }

    // renounce role is only for yourself, so no modifier should have been added to this
    function renounceRole(
        bytes32 role,
        address account
    ) public override(IAccessControlUpgradeable, AccessControlUpgradeable) {
        require(
            LibDiamond.diamondStorage().contractOwner != account,
            "Cannot renounce superAdmin from any Roles"
        );
        super.renounceRole(role, account);
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public override(IAccessControlUpgradeable, AccessControlUpgradeable) {
        require(
            LibDiamond.diamondStorage().contractOwner != account,
            "Cannot revoke superAdmin from any Roles"
        );
        // this checks that only the admin(s) of the Role can revoke a Role
        super.revokeRole(role, account);
    }

    modifier onlySuperAdminRole() {
        require(LibDiamond.diamondStorage().contractOwner == msg.sender, "Only SuperAdmin allowed");
        _;
    }

    modifier onlyAdminRole() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Account doesn't have admin role");
        _;
    }

    modifier onlyAutoIrrigateAdminRole() {
        require(
            hasRole(AUTO_IRRIGATE_ADMIN_ROLE, msg.sender),
            "Account doesn't have auto irrigate admin role"
        );
        _;
    }
}
