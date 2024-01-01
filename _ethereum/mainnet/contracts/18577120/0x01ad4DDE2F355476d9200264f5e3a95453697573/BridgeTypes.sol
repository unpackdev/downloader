// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

/// @notice Library that defines cross chain containers for Bridge.
library BridgeTypes {
    // -----------------------------------------------------------------------
    //                              Bridge
    // -----------------------------------------------------------------------

    /// @dev Struct containing cross chain target information
    /// @param chainId Chain id in Bridge format
    /// @param trustedRemote Trusted cross chain receiver address
    struct Target {
        uint256 chainId;
        bytes trustedRemote;
    }

    /// @dev Struct containing cross chain source information
    /// @param srcChainId Current chain id in Bridge format
    /// @param srcAddress Address of sender
    struct Source {
        uint256 srcChainId;
        bytes srcAddress;
    }

    /// @dev Struct containing cross chain transaction
    /// @param nonce Cross chain nonce of tx
    /// @param func String name of Substrate function to call
    /// @param args Byte-encoded cross-chain arguments for function
    /// @param options Byte-encoded cross chain settings for Bridge tx
    struct Transaction {
        uint256 nonce;
        bytes4 func;
        bytes args;
        bytes options;
    }
}
