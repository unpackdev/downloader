// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library MetadataUriStorageV1 {
    struct Layout {
        // =============================================================
        // Storage
        // =============================================================

        // URI prefix.
        string _uriPrefix;
        // URI suffix.
        string _uriSuffix;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("DegenToonz.contracts.storage.MetadataUriStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
