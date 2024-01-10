// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./SeenConstants.sol";

/**
 * @title AccessController
 *
 * @notice Implements centralized role-based access for Seen.Haus contracts.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract AccessController is AccessControlUpgradeable, SeenConstants  {

    /**
     * @notice Constructor
     *
     * Grants ADMIN role to deployer.
     * Sets ADMIN as role admin for all other roles.
     */
    constructor() {
        _setupRole(MULTISIG, msg.sender); // Renounce role and grant to multisig once initial setup is complete
        _setRoleAdmin(MULTISIG, ADMIN); // Shift role admin to MULTISIG once initial setup is complete
        _setupRole(ADMIN, msg.sender);
        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(SELLER, ADMIN);
        _setRoleAdmin(MINTER, ADMIN);
        _setRoleAdmin(ESCROW_AGENT, ADMIN);
        _setRoleAdmin(MARKET_HANDLER, ADMIN);
        _setRoleAdmin(UPGRADER, ADMIN);
    }

    function shiftRoleAdmin(bytes32 role, bytes32 adminRole) external onlyRole(getRoleAdmin(role)) {
        _setRoleAdmin(role, adminRole);
    }

}