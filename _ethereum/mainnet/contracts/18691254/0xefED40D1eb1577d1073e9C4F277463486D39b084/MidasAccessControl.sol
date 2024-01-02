// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AccessControlUpgradeable.sol";

import "./MidasAccessControlRoles.sol";
import "./MidasInitializable.sol";

/**
 * @title MidasAccessControl
 * @notice Smart contract that stores all roles for Midas project
 * @author RedDuck Software
 */
contract MidasAccessControl is
    AccessControlUpgradeable,
    MidasInitializable,
    MidasAccessControlRoles
{
    /**
     * @notice upgradeable pattern contract`s initializer
     */
    function initialize() external initializer {
        __AccessControl_init();
        _setupRoles();
    }

    /**
     * @notice grant multiple roles to multiple users
     * in one transaction
     * @dev length`s of 2 arays should match
     * @param roles array of bytes32 roles
     * @param addresses array of user addresses
     */
    function grantRoleMult(bytes32[] memory roles, address[] memory addresses)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(roles.length == addresses.length, "MAC: mismatch arrays");

        for (uint256 i; i < roles.length; i++) {
            _grantRole(roles[i], addresses[i]);
        }
    }

    /**
     * @notice revoke multiple roles from multiple users
     * in one transaction
     * @dev length`s of 2 arays should match
     * @param roles array of bytes32 roles
     * @param addresses array of user addresses
     */
    function revokeRoleMult(bytes32[] memory roles, address[] memory addresses)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(roles.length == addresses.length, "MAC: mismatch arrays");

        for (uint256 i; i < roles.length; i++) {
            _revokeRole(roles[i], addresses[i]);
        }
    }

    /**
     * @dev setup roles during the contracts initialization
     */
    function _setupRoles() private {
        address admin = msg.sender;

        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        _setupRole(DEPOSIT_VAULT_ADMIN_ROLE, admin);
        _setupRole(REDEMPTION_VAULT_ADMIN_ROLE, admin);

        _setRoleAdmin(BLACKLISTED_ROLE, BLACKLIST_OPERATOR_ROLE);
        _setRoleAdmin(GREENLISTED_ROLE, GREENLIST_OPERATOR_ROLE);

        _setupRole(GREENLIST_OPERATOR_ROLE, admin);
        _setupRole(BLACKLIST_OPERATOR_ROLE, admin);

        _setupRole(M_TBILL_MINT_OPERATOR_ROLE, admin);
        _setupRole(M_TBILL_BURN_OPERATOR_ROLE, admin);
        _setupRole(M_TBILL_PAUSE_OPERATOR_ROLE, admin);
    }
}
