// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Errors library
 * @author Exoswap
 * @notice Defines the error messages emitted by the different contracts of bridge exoswap protocol
 * @dev Error messages prefix glossary:
 *  - B = Base errors
 *  - R = Relayer errors
 *  - M = Manager errors
 *  - BR = Router errors
 */
library Errors {
    //common errors
    string public constant B_ENTITY_EXIST = "1";
    string public constant B_ENTITY_NOT_EXIST = "2";
    string public constant B_LENGTH_MISMATCH = "3";
    string public constant B_INSUFFICIENT_BALANCE = "4";
    string public constant B_SEND_REVERT = "5";
    string public constant B_NOT_LISTED = "6";
    string public constant B_ZERO_ADDRESS = "7";
    string public constant B_EMPTY_BATCH = "8";
    string public constant B_ZERO_AMOUNT = "9";
    string public constant B_INVALID_EVENT = "10";
    string public constant B_EXPIRED = "11";
    string public constant B_AMOUNT_TOO_LOW = "12";
    string public constant B_GAS_OVERFLOW = "13";
    string public constant B_LOCKED = "14";
    string public constant B_PROTECTED_ADDRESS = "15";
    //relayer
    string public constant R_RESERVED_ENTITY = "R1";
    string public constant R_RESERVED_OWNER = "R2";
    string public constant R_NOT_APP_OWNER = "R3";
    string public constant R_ACQUIRE_FAILED = "R4";
    //manager
    string public constant M_ONLY_EXTERNAL = "M1";
    string public constant M_MAX_SIZE = "M2";
    string public constant M_SAME_CHAIN = "M3";
    string public constant M_SOURCE_EXIST = "M4";
    string public constant M_TARGET_EXIST = "M5";
    //router
    string public constant BR_WRONG_SOURCE_CHAIN = "BR1";
    string public constant BR_WRONG_TARGET_CHAIN = "BR2";
    string public constant BR_COMMITMENT_KNOWN = "BR3";
    string public constant BR_INVALID_SIGNATURES = "BR4";
    string public constant BR_AMOUNT_OVERFLOW = "BR5";
    string public constant BR_FEE_OVERFLOW = "BR6";
    string public constant BR_LIMIT_OVERFLOW = "BR7";
    string public constant BR_WRONG_EXECUTOR = "BR8";
    string public constant BR_FEE_TOO_LOW = "BR9";
    string public constant BR_EXECUTION_FAILED = "BR10";
}
