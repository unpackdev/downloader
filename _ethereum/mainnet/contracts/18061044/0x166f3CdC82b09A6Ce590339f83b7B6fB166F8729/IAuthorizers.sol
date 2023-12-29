// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title Authorizers interface
 *
 * @notice Defines interface for authorizers
 */
interface IAuthorizers {
    /**
     * @notice A function, which is used to authorize given signature
     * @param message_ The message that is being authorized
     * @param signatures_ The signatures for the given message
     * @return bool The result of check
     */
    function authorize(bytes32 message_, bytes[] calldata signatures_)
        external returns(bool);

    /**
     * @notice A function, which is used to generate message hash for the given parameters
     * @param to_ The address to perform transaction for
     * @param amount_ The transaction token amount
     * @param txid_ The transaction id
     * @param nonce_ The transaction nonce
     * @return bytes32 The Ethereum signature formatted hash
     */
    function messageHash(
        address to_,
        uint256 amount_,
        bytes calldata txid_,
        uint256 nonce_
    ) external returns (bytes32);
}
