/*
 * CurioFoundersEditionNFTsMigrator
 *
 * Copyright ©️ 2021 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2021 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Legacy.sol";

contract CurioFoundersEditionNFTsMigrator is IERC721Receiver {

    /// @notice Old NFT collection
    IERC721Legacy public oldCollection;

    /// @notice New NFT collection
    IERC721 public newCollection;

    /// @notice Emitted when `tokenId` token is migrated to new collection.
    event MigratedToNew(address owner, uint256 tokenId);

    /// @notice Emitted when `tokenId` token is migrated to old collection.
    event MigratedToOld(address owner, uint256 tokenId);

    constructor (IERC721Legacy _oldCollection, IERC721 _newCollection) {
        oldCollection = _oldCollection;
        newCollection = _newCollection;
    }

    /**
     * @notice Migrate to old NFT collection.
     * @param _tokenId NFT id
     */
    function migrateToOld(uint256 _tokenId) external {
        require(oldCollection.ownerOf(_tokenId) == address(this), "migrateToOld: unsupported tokenId");

        newCollection.transferFrom(msg.sender, address(this), _tokenId);
        oldCollection.transfer(msg.sender, _tokenId);

        emit MigratedToOld(msg.sender, _tokenId);
    }

    /**
     * @notice Migrate to new NFT collection.
     * @param _tokenId NFT id
     */
    function migrateToNew(uint256 _tokenId) external {
        require(newCollection.ownerOf(_tokenId) == address(this), "migrateToNew: unsupported tokenId");

        oldCollection.transferFrom(msg.sender, address(this), _tokenId);
        newCollection.transferFrom(address(this), msg.sender, _tokenId);

        emit MigratedToNew(msg.sender, _tokenId);
    }

    /**
     * @notice Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
