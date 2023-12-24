// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ErrorReporter {
    /*********************************** Errors ****************************************/

    /**
     * Not a valid contract address
     */
    error InvalidContractAddress();

    /**
     * Not a valid token type
     */
    error InvalidTokenType();

    /**
     * Input is zero address
     */
    error ZeroAddress();

    /**
     * Request was called by a non service account
     * @param caller is the caller of the method
     */
    error NotService(address caller);

    /**
     * Request was called by a non user account
     * @param caller is the caller of the method
     */
    error NotUser(address caller);

    /**
     * Safeguard does not exist
     */
    error SafeguardDoesNotExist();

    /**
     * Invalid token ID
     */
    error InvalidTokenID();
}