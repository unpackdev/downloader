// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library DiamondWritableRevokableStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("keepers.contracts.storage.diamond.writable.revokable");

    struct Layout {
        bool isUpgradeabiltyRevoked;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
