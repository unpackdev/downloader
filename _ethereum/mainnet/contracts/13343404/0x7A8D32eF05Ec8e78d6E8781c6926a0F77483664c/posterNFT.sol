// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract PhunkPosters is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("PhunkRockPosters", "PHUNKR") {}

    function contractURI() public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/Qmc8gbDWsExYPs8Vq1QjR9eJjMtgrqouhW4E86Wv71HG7H";
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), uri); 
        _tokenIdCounter.increment();
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
