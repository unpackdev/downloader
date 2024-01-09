// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public maxSupply = 500;

    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("ExoticTravellers", "ExT") {}

    function tokenURI(uint256 tokenId) 
        public
        view
        virtual
        override
        returns (string memory) 
    {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) 
        internal
        virtual
    {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function mintNFT(address recipient, string memory newTokenURI)
        public
        onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        require(newItemId <= maxSupply);

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, newTokenURI);

        return newItemId;
    }
}
