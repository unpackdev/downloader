// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title Message
 *
 * @notice Represents a set of structs, which are used for Bridge operations
 */
library Structs {
    /**
     * @title Args
     *
     * @notice Represents arguments used for mint WZCN operation
     */
    struct Args {
        /// @notice The address to mint the tokens to
        address to;

        /// @notice The amount of tokens to mint
        uint256 amount;

        /// @notice The txid of the burn transaction on the 0chain
        bytes txid;

        /// @notice The burn nonce from ZCN used to sign the message
        uint256 nonce;
    }

    /**
     * @title Authorizer
     *
     * @notice Represents authorizer used for DEX operations
     */
    struct Authorizer {
        /// @notice Index of the authorizers
        uint256 index;

        /// @notice Flag, which is used to check, if authorizer exists
        bool isAuthorizer;
    }
}
