// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./LuffyMarket.sol";
import "./ReentrancyGuard.sol";

contract LuffyNFT is ERC721, ERC721Enumerable, ERC721URIStorage, ReentrancyGuard {
    uint256 public currentTokenId = 1;
    LuffyMarket public market;

    constructor(
        string memory _name,
        string memory _symbol,
        address _market
    ) ERC721(_name, _symbol) {
        market = LuffyMarket(_market);
        market.collectionCreated();
    }

    function mint(string memory _tokenURI) public nonReentrant {
        uint256 initialTokenId = currentTokenId;

        _safeMint(msg.sender, currentTokenId);
        _setTokenURI(currentTokenId, _tokenURI);
        _approve(address(market), currentTokenId);
        currentTokenId += 1;

        market.nftMinted(initialTokenId, currentTokenId - 1, _tokenURI);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
