// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Traits.sol";


contract NFT is ERC721, ERC721Enumerable, ERC721Burnable, Traits {
    uint256 public tokenIdCounter;
    string public baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 mutagenFrequency_
    ) ERC721(name_, symbol_) Traits(mutagenFrequency_) {
        baseURI = baseURI_;
    }

    function _mintWithTraits(address to) internal {
        _genTraits();
        _safeMint(to, tokenIdCounter);
        tokenIdCounter++;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURI;
    }

    function mutate(uint256 tokenId1, uint256 tokenId2) external virtual {
        require(ownerOf(tokenId1) == _msgSender(), "N2");
        require(ownerOf(tokenId2) == _msgSender(), "N3");

        _mutate(tokenId1, tokenId2);

        _safeMint(_msgSender(), tokenIdCounter);
        tokenIdCounter++;

        _burn(tokenId1);
        _burn(tokenId2);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
