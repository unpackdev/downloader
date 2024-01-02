// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./IAddressResolver.sol";

library MixinAddressResolverStorage {
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256("sf.storage.mixinAddressResolver")) - 1);

    struct Storage {
        IAddressResolver resolver;
        mapping(bytes32 contractName => address contractAddress) addressCache;
    }

    function slot() internal pure returns (Storage storage r) {
        bytes32 _slot = STORAGE_SLOT;
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := _slot
        }
    }
}
