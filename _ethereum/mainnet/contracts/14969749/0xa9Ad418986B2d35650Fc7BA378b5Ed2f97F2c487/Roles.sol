// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AccessControlEnumerableUpgradeable.sol";

contract Roles is AccessControlEnumerableUpgradeable {
    /* ================================================ ADMIN ROLE ================================================ */

    /**
     * @dev Modifier that checks that the sender has the {DEFAULT_ADMIN_ROLE} role.
     *
     * Reverts with a standardized message including the required role. See {AccessControl-_checkRole}.
     */
    modifier onlyVaultAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    /**
     * @dev transfer the {DEFAULT_ADMIN_ROLE} role to another wallet.
     */
    function transferAdmin(address _to) external onlyVaultAdmin {
        super.grantRole(DEFAULT_ADMIN_ROLE, _to);
        super.revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * ================================================= OTHER ROLES =================================================
     *
     * Roles are defined as functions to avoid issues with upgradeability if we want to add and remove roles.
     *
     */

    /**
     * @dev the minter role.
     */
    function MINTER_ROLE() internal pure returns (bytes32) {
        return keccak256('MINTER_ROLE');
    }

    /**
     * @dev Modifier that checks that the sender has the {MINTER_ROLE} role.
     *
     * Reverts with a standardized message including the required role. See {AccessControl-_checkRole}.
     */
    modifier onlyMinter() {
        _checkRole(MINTER_ROLE(), _msgSender());
        _;
    }

    /**
     * @dev grant the BURNER_ROLE role that allows to minting new tokens.
     */
    function grantMinterRole(address account) external onlyVaultAdmin {
        super.grantRole(MINTER_ROLE(), account);
    }

    /**
     * @dev revoke the MINTER_ROLE role.
     */
    function revokeMinterRole(address account) external onlyVaultAdmin {
        super.revokeRole(MINTER_ROLE(), account);
    }
}
