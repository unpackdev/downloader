// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721Metadata.sol";
import "./ERC721.sol";

contract NftBakeableMetadata is IERC721Metadata, ERC721 {
    // Optional persistence for individual token URIs
    mapping(uint256 => string) private _tokenURIs;
    string internal baseURIString = "https://www.schrodingerslabs.com/api/metadata/";

    constructor(
        string memory envBaseURI,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        baseURIString = envBaseURI;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURIString;
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721Metadata, ERC721) returns (string memory) {
        string memory tokenURI_ = _tokenURIs[tokenId];

        // If tokenURI is set, then return the saved string (encoded data or link)
        if (bytes(tokenURI_).length > 0) {
            return tokenURI_;
        }
        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string calldata token_URI) internal virtual {
        require(_exists(tokenId), "NftBakedMetadata: URI set of nonexistent token");
        require((bytes(token_URI).length > 0), "NftBakedMetadata: tokenURI needs to be supplied");
        _tokenURIs[tokenId] = token_URI;
    }

    function _unsetTokenURI(uint256 tokenId) internal virtual {
        require(_exists(tokenId), "NftBakedMetadata: URI set of nonexistent token");
        delete _tokenURIs[tokenId];
    }

    function _setBaseURI(string calldata baseURI) internal virtual {
        require((bytes(baseURI).length > 0), "NftBakedMetadata: baseURI needs to be supplied");
        baseURIString = baseURI;
    }
}
