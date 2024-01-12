// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

/// @title DIS x CHAIN/SAW

contract DISxCHAINSAW is ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 private nextTokenId;
    mapping(uint256 => bool) public metadataFrozen;
    
    constructor() ERC721("DIS x CHAIN/SAW", "DIS") {}

    function mint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string calldata _tokenURI) external onlyOwner {
        require(!metadataFrozen[tokenId], "Metadata is frozen");
        _setTokenURI(tokenId, _tokenURI);
    }

    function freezeMetadata(uint256 tokenId) external onlyOwner {
        _requireMinted(tokenId);
        require(metadataFrozen[tokenId] == false, "Metadata already frozen.");    
        metadataFrozen[tokenId] = true;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }    
}