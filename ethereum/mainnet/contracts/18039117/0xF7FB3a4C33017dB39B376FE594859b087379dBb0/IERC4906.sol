// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title EIP-721 Metadata Update Extension
interface IERC4906 {
    event MetadataUpdate(uint256 _tokenId);

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}
