// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

// Email the security officer for any issues:  davidblythe@grav-c.io
//
// Required to deploy:
//      Logo Uploaded to IPFS
//      metadata.json Uploaded to IPFS, with an 'image: "ipfs://"' entry to your Logo
//
// When deploying, enter Name, Symbol of your choice
// For baseURI, point to the metadata.json ipfs:// entry
// 
// You will never have to deploy another contract for Logo Updates
// Just use setBaseURI to the a new metadata.json ipfs:// entry
// 
// No cost to mint, no cost to update, logo for twitter, etc.

contract DarkMatterMangaLogo is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    uint public constant MAX_SUPPLY = 1;
    string public baseTokenURI;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        setBaseURI(baseURI);
        mintLogo(MAX_SUPPLY);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory newBaseTokenURI) public onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    function mintLogo(uint256 _mintAmount) public onlyOwner {
        uint256 currentSupply = totalSupply();
        require(_mintAmount > 0);
        require(currentSupply + _mintAmount <= MAX_SUPPLY);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}