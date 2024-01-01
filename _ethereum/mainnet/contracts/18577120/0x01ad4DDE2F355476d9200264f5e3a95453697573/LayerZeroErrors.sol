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

/**************************************

    LayerZero errors
    
**************************************/

/// @dev All errors used in LayerZero cross chain communication
library LayerZeroErrors {
    // -----------------------------------------------------------------------
    //                              Send
    // -----------------------------------------------------------------------

    error UnsupportedLayerZeroChain(uint256 chainId); // 0x9e90d5d0
    error InvalidLayerZeroFee(); // 0x6142d241
    error InvalidNativeSent(uint256 value, uint256 fee); // 0x7166d3ed

    // -----------------------------------------------------------------------
    //                              Receive
    // -----------------------------------------------------------------------

    error ChainNotSupported(uint16 chainId); // 0xec2a2f0f
    error UntrustedRemote(bytes remote); // 0xd39d950e
    error NonceExpired(uint16 chainId, uint256 nativeChainId, bytes srcAddress, uint64 nonce); // 0x286d7ff2
    error UnsupportedFunction(bytes4 functionSelector); // 0x1a366124

    // -----------------------------------------------------------------------
    //                              Retry
    // -----------------------------------------------------------------------

    error MessageNotExists(uint16 srcChainId, bytes srcAddress, uint64 nonce); // 0x2e4f65fa
    error InvalidPayload(bytes32 storedPayload, bytes32 sentPayload); // 0xca89b547
}
