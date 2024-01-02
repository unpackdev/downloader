// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title MidasAccessControlRoles
 * @notice Base contract that stores all roles descriptors
 * @author RedDuck Software
 */
abstract contract MidasAccessControlRoles {
    /**
     * @notice actor that can change green list statuses of addresses
     */
    bytes32 public constant GREENLIST_OPERATOR_ROLE =
        keccak256("GREENLIST_OPERATOR_ROLE");

    /**
     * @notice actor that can change black list statuses of addresses
     */
    bytes32 public constant BLACKLIST_OPERATOR_ROLE =
        keccak256("BLACKLIST_OPERATOR_ROLE");

    /**
     * @notice actor that can mint mTBILL
     */
    bytes32 public constant M_TBILL_MINT_OPERATOR_ROLE =
        keccak256("M_TBILL_MINT_OPERATOR_ROLE");

    /**
     * @notice actor that can burn mTBILL
     */
    bytes32 public constant M_TBILL_BURN_OPERATOR_ROLE =
        keccak256("M_TBILL_BURN_OPERATOR_ROLE");

    /**
     * @notice actor that can pause mTBILL
     */
    bytes32 public constant M_TBILL_PAUSE_OPERATOR_ROLE =
        keccak256("M_TBILL_PAUSE_OPERATOR_ROLE");

    /**
     * @notice actor that have admin rights in deposit vault
     */
    bytes32 public constant DEPOSIT_VAULT_ADMIN_ROLE =
        keccak256("DEPOSIT_VAULT_ADMIN_ROLE");

    /**
     * @notice actor that have admin rights in redemption vault
     */
    bytes32 public constant REDEMPTION_VAULT_ADMIN_ROLE =
        keccak256("REDEMPTION_VAULT_ADMIN_ROLE");

    /**
     * @notice actor that is greenlisted
     */
    bytes32 public constant GREENLISTED_ROLE = keccak256("GREENLISTED_ROLE");

    /**
     * @notice actor that is blacklisted
     */
    bytes32 public constant BLACKLISTED_ROLE = keccak256("BLACKLISTED_ROLE");
}
