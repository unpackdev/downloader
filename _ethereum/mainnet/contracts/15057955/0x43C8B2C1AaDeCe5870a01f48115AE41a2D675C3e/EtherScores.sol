// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract EtherScores is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;
    mapping(uint256 => bool) public sealedTokens;
    bool public isCollectionSealed;

    constructor() ERC721("EtherScores", "ES") {}

    function safeMint(address to, string memory uri) external onlyOwner {
        _tokenIdCounter++;
        _safeMint(to, _tokenIdCounter);
        _setTokenURI(_tokenIdCounter, uri);
    }

    function updateMetadata(uint256 tokenId, string memory uri) external onlyOwner {
        require(!isCollectionSealed, "collection sealed");
        require(!sealedTokens[tokenId], "collection sealed");
        _setTokenURI(tokenId, uri);
    }

    function sealToken(uint256 tokenId) external onlyOwner {
        sealedTokens[tokenId] = true;
    }

    function sealCollection() external onlyOwner {
        isCollectionSealed = true;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
