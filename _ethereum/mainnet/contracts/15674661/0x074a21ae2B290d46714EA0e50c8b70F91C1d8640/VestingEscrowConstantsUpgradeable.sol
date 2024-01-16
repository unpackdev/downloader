// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title VestingEscrowConstantsUpgradeable
 * @author NeatFi
 * @notice This contract holds the constants for the VestingEscrow contract.
 */
contract VestingEscrowConstantsUpgradeable is Initializable {
    // Role constant for protocol admins.
    bytes32 public constant PROTOCOL_ADMIN = keccak256("PROTOCOL_ADMIN");

    // Role constant for authorized operator contracts.
    bytes32 public constant AUTHORIZED_OPERATOR =
        keccak256("AUTHORIZED_OPERATOR");

    // Timestamp representation of a day.
    uint256 public constant DAY = 86400;

    // Timestamp representation of a month.
    uint256 public constant MONTH = 30 * DAY;

    // Timestamp representation of a year.
    uint256 public constant YEAR = 12 * MONTH;

    /** Initializers */

    function __VestingEscrowConstants_init() internal initializer {
        __VestingEscrowConstants_init_unchained();
    }

    function __VestingEscrowConstants_init_unchained() internal initializer {}
}
