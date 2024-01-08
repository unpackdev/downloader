// SPDX-License-Identifier: MIT

/**
 * Copyright 2021, Bitlabs Pte. Ltd. All Rights Reserved.
 */
 

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

contract ARTHAUS is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 private _maxSupply = 1000;
    using Strings for uint256;

    string public ARTHAUS_PROVENANCE = "02e9a1bc0ce42d406ed59dbdcf82421c";
    string public ARTWORK_CREATOR = "Nicholas Keays";
    
    constructor() ERC721("ART HAUS", "ARTHAUS") {}

    function safeMint(uint256 numberOfNfts, address to) public onlyOwner {
        require(totalSupply() < _maxSupply, "Minting would exceed max supply of memberships");
        require(numberOfNfts > 0, "Cannot mint 0 NFTs");
    
        for (uint i = 0; i < numberOfNfts; i++) {
        uint mintIndex = totalSupply();

        require(mintIndex < _maxSupply, "Exceeds max number of memberships in existence");

        _safeMint(to, mintIndex);
        _tokenIdCounter.increment();
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafkreiawd4plwfq64rjchecaamowtwkc4r2y44xt2e5nugu5gf2mdhakq4";
    }

     function maxSupply() public view returns (uint256){
        return _maxSupply;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}