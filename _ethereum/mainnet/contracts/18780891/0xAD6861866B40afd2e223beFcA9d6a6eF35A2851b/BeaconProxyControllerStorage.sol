// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

library BeaconProxyControllerStorage {
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256("sf.storage.beaconProxyController")) - 1);

    struct Storage {
        mapping(bytes32 contractName => address contractAddress) registeredBeaconProxies;
    }

    function slot() internal pure returns (Storage storage r) {
        bytes32 _slot = STORAGE_SLOT;
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := _slot
        }
    }
}
