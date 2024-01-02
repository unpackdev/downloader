// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./AccessControl.sol";
import "./IACLManager.sol";

/**
 * @title ACLManager
 *
 * @notice Access Control List Manager. Main registry of system roles and permissions.
 */
contract ACLManager is IACLManager, AccessControl {
    bytes32 public constant CEGA_ADMIN_ROLE = keccak256("CEGA_ADMIN");
    bytes32 public constant TRADER_ADMIN_ROLE = keccak256("TRADER_ADMIN");
    bytes32 public constant OPERATOR_ADMIN_ROLE = keccak256("OPERATOR_ADMIN");
    bytes32 public constant SERVICE_ADMIN_ROLE = keccak256("SERVICE_ADMIN");

    /**
     * @dev Constructor
     * @dev The ACL admin should be initialized at the address manager beforehand
     */
    constructor(address _cegaAdmin) {
        _grantRole(CEGA_ADMIN_ROLE, _cegaAdmin);
        _setRoleAdmin(CEGA_ADMIN_ROLE, CEGA_ADMIN_ROLE);
        _setRoleAdmin(TRADER_ADMIN_ROLE, CEGA_ADMIN_ROLE);
        _setRoleAdmin(OPERATOR_ADMIN_ROLE, CEGA_ADMIN_ROLE);
        _setRoleAdmin(SERVICE_ADMIN_ROLE, CEGA_ADMIN_ROLE);
    }

    function setRoleAdmin(
        bytes32 role,
        bytes32 adminRole
    ) external onlyRole(CEGA_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }

    function addCegaAdmin(address admin) external {
        grantRole(CEGA_ADMIN_ROLE, admin);
    }

    function removeCegaAdmin(address admin) external {
        revokeRole(CEGA_ADMIN_ROLE, admin);
    }

    function addTraderAdmin(address admin) external {
        grantRole(TRADER_ADMIN_ROLE, admin);
    }

    function removeTraderAdmin(address admin) external {
        revokeRole(TRADER_ADMIN_ROLE, admin);
    }

    function addOperatorAdmin(address admin) external {
        grantRole(OPERATOR_ADMIN_ROLE, admin);
    }

    function removeOperatorAdmin(address admin) external {
        revokeRole(OPERATOR_ADMIN_ROLE, admin);
    }

    function addServiceAdmin(address admin) external {
        grantRole(SERVICE_ADMIN_ROLE, admin);
    }

    function removeServiceAdmin(address admin) external {
        revokeRole(SERVICE_ADMIN_ROLE, admin);
    }

    function isCegaAdmin(address admin) external view returns (bool) {
        return hasRole(CEGA_ADMIN_ROLE, admin);
    }

    function isTraderAdmin(address admin) external view returns (bool) {
        return hasRole(TRADER_ADMIN_ROLE, admin);
    }

    function isOperatorAdmin(address admin) external view returns (bool) {
        return hasRole(OPERATOR_ADMIN_ROLE, admin);
    }

    function isServiceAdmin(address admin) external view returns (bool) {
        return hasRole(SERVICE_ADMIN_ROLE, admin);
    }
}
