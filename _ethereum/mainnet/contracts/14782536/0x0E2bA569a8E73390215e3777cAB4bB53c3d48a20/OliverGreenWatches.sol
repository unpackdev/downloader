// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract OliverGreenWatches is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;
    
    constructor() ERC721("Oliver Green Watches", "OGW") {
        mintTo(owner(), "ipfs://QmYnUyDyQF9oshEuK86jUBPjiPNqPx1vo5LvZPX5kyKBBv");
    }

    function totalSupply() public view returns (uint256) {
        return currentTokenId.current();
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function mintTo(address recipient, string memory _tokenURI)
        public onlyOwner
        returns (uint256)
    {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        return newItemId;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        _transferOwnership(newOwner);
    }

    event PermanentURI(string _value, uint256 indexed _id);
}