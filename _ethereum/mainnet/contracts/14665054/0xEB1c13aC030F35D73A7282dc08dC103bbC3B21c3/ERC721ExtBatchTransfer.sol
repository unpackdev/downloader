// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @author: unimint.org

/**
 * @title ERC721ExtBatchTransfer
 * @notice Transfer ERC721 tokens to a list of users
 */
abstract contract ERC721ExtBatchTransfer {
    struct TransferInfo {
        uint256 tokenId;
        address reciever;
    }

    function batchTransfer(TransferInfo[] calldata list) external virtual;
}
