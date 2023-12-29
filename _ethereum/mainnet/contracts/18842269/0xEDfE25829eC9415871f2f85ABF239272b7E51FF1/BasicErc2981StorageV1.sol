// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library BasicErc2981StorageV1 {
    struct Layout {
        // =============================================================
        // Storage
        // =============================================================

        // The address to send the royalties to.
        address _royaltiesReveiver;
        // The fraction that should be used for royalties (100 = 1%).
        uint256 _royaltiesFraction;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("DegenToonz.contracts.storage.BasicErc2981");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
