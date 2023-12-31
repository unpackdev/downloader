// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Errors library
 * @author JusticeDAO
 * @notice Defines the error messages emitted by the different contracts of the Donate contract
 */
library Errors {
    // The caller of the function is not a account owner
    string public constant INVALID_SIGNER = '1';
    string public constant RECEIVE_FALLBACK_PROHIBITED = '2';
    string public constant INVALID_RECIPIENT = '3';
    string public constant RECIPIENT_ALREADY_EXIST = '4';
    string public constant RECIPIENT_NOT_FOUND = '5';
}
