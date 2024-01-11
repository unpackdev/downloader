// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Traits.sol";


contract NFT is ERC721, ERC721Enumerable, ERC721Burnable, Traits {
    uint256 public mutagenFrequency;

    uint256 public tokenIdCounter;
    string public baseURI;
    Trait[] tmp;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 mutagenFrequency_
    ) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        mutagenFrequency = mutagenFrequency_;
    }

    function _mintWithTraits(address to) internal {
        if (_randint(mutagenFrequency) == 0) {
            _genMutagen();
        } else {
            _genTraits(true, 0, 0);
        }
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
        require(_nfts[tokenId1].traits.length + _nfts[tokenId2].traits.length > 2, "N5");

        tmp = _nfts[_nfts.length - 1].traits;
        uint256 _hue = hue[hue.length - 1];
        uint256 _hueBg = hueBg[hueBg.length - 1];
        _nfts.pop();
        hue.pop();
        hueBg.pop();

        _genTraits(false, tokenId1, tokenId2);
        _safeMint(_msgSender(), tokenIdCounter);
        tokenIdCounter++;

        _nfts.push();
        _NFT storage nft = _nfts[_nfts.length - 1];
        nft.traits = tmp;
        for (uint256 i; i < tmp.length; i++) {
            nft.values[tmp[i].trait] = tmp[i].value;
        }

        hue.push(_hue);
        hueBg.push(_hueBg);

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
