// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import "./Address.sol";
import "./MythicsV2.sol";

/**
 * @notice ERC721 Transfer Listener
 */
interface IERC721TransferListener {
    /**
     * @notice Hook called upon token transfers.
     */
    function onTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) external;
}

library MythicsV3Storage {
    bytes32 internal constant STORAGE_SLOT = keccak256("Mythics.V3.storage.location");

    /**
     * @notice This is the storage layout for the Mythics V3 contract.
     * @dev The fields in this struct MUST NOT be removed, renamed, or reordered. Only additionas are allowed to keep
     * the storage layout compatible between upgrades.
     */
    struct Layout {
        IERC721TransferListener transferListener;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/**
 * @title Mythics V3
 * @notice Adding notifications on transfer
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract MythicsV3 is MythicsV2 {
    using Address for address;

    struct InitArgsV3 {
        IERC721TransferListener listener;
    }

    function initializeV3(InitArgsV3 memory init) public virtual reinitializer(3) {
        MythicsV3Storage.layout().transferListener = init.listener;
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override
    {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);

        IERC721TransferListener listener = MythicsV3Storage.layout().transferListener;

        // Trying to notify EOAs would result in reverts that would block transfers. We therefore return early in this
        // case.
        if (!address(listener).isContract()) {
            return;
        }

        try listener.onTransfer{gas: 30_000}(from, to, firstTokenId, batchSize) {} catch {}
    }
}
