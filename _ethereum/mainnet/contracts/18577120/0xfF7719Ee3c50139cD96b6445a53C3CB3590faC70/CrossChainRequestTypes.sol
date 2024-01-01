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

// Local imports - Structs
import "./StorageTypes.sol";
import "./EnumTypes.sol";

/// @notice Library that defines requests sent from frontend to smart contracts.
library CrossChainRequestTypes {
    // -----------------------------------------------------------------------
    //                              Cross chain
    // -----------------------------------------------------------------------

    /// @dev Struct containing chosen cross-chain provider and encoded data.
    /// @param provider Cross chain provider
    /// @param data Data encoding message in format for specific provider
    struct CrossChainData {
        EnumTypes.CrossChainProvider provider;
        bytes data;
    }

    /// @dev Struct containing base for cross-chain message.
    /// @param sender Address of sender
    /// @param nonce Nonce of cross-chain message
    struct CrossChainBase {
        address sender;
        uint256 nonce;
    }

    // -----------------------------------------------------------------------
    //                              LayerZero
    // -----------------------------------------------------------------------

    /// @dev Struct containing cross chain message in LayerZero format
    /// @param payload Encoded cross-chain call with data
    /// @param additionalParams Additional parameters for LayerZero
    /// @param fee Fee covering execution cost
    struct LayerZeroData {
        bytes payload;
        bytes additionalParams;
        uint256 fee;
    }

    // -----------------------------------------------------------------------
    //                              AlephZero
    // -----------------------------------------------------------------------

    /// @dev Struct containing cross chain message in AlephZero format
    /// @param nonce Cross chain nonce of tx
    /// @param fee Unused fee if we would like to publish Bridge
    /// @param func String name of Substrate function to call
    /// @param args Byte-encoded cross-chain arguments for function
    /// @param options Byte-encoded cross chain settings for Bridge tx
    struct AlephZeroData {
        uint256 nonce;
        uint256 fee;
        bytes4 func;
        bytes args;
        bytes options;
    }
}
