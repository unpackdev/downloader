// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

library ChonkyNFTStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("chonky.contracts.storage.ChonkyNFT");

    struct RevealRange {
        uint256 startId;
        uint256 endId;
        uint256 offset; // Offset to apply for this interval
    }

    struct Layout {
        address implementation;
        uint256 currentId;
        uint256[] genomes;
        // Offset IDs to randomize distribution when revealing
        uint256 _deprecated_offset;
        // Address of chonkyAttributes contract
        address chonkyAttributes;
        // Address of chonkyMetadata contract
        address chonkyMetadata;
        // Address of chonkySet contract
        address chonkySet;
        // Timestamp at which minting starts
        uint256 startTimestamp;
        // Reveal ranges
        RevealRange[] revealRanges;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
