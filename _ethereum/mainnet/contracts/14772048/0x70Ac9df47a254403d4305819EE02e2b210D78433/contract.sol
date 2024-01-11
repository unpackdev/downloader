// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Metarocks is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIdCounter;

    mapping(string => uint256) existingURIs;

    constructor() ERC721("Metarocks", "Metarocks") {}

    function payToMint(address wallet, string memory metadata)
        public
        payable
        returns (uint256)
    {
        require(existingURIs[metadata] != 1, "NFT already minted!");
        require(msg.value >= 0.02 ether, "Need to pay up!");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(wallet, tokenId);
        _setTokenURI(tokenId, metadata);

        existingURIs[metadata] = 1;

        withdraw();

        return _tokenIdCounter.current();
    }

    function getCurrentTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function isContentOwned(string memory uri) public view returns (bool) {
        return existingURIs[uri] == 1;
    }

    function withdraw() public returns (bool) {
        payable(owner()).transfer(address(this).balance);
        return true;
    }
}
