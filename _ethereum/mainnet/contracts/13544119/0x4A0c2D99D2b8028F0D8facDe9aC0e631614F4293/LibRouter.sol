// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

library LibRouter {
    bytes32 constant STORAGE_POSITION = keccak256("router.storage");

    /// @notice Struct containing information about a token's address and its native chain
    struct NativeTokenWithChainId {
        uint8 chainId;
        bytes token;
    }

    struct Storage {
        bool initialized;

        // Maps chainID => (nativeToken => wrappedToken)
        mapping(uint8 => mapping(bytes => address)) nativeToWrappedToken;

        // Maps wrapped tokens in the current chain to their native chain + token address
        mapping(address => NativeTokenWithChainId) wrappedToNativeToken;

        // Storage metadata for transfers. Maps sourceChain => (transactionId => metadata)
        mapping(uint8 => mapping(bytes32 => bool)) hashesUsed;

        // Address of the ALBT token in the current chain
        address albtToken;

        // The chainId of the current chain
        uint8 chainId;
    }

    function routerStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
