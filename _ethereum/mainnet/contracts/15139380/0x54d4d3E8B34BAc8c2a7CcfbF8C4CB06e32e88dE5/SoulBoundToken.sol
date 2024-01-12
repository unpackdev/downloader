// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC-4973.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract SoulBoundToken is ERC4973, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC4973("RPD Pass SBT", "RPS") {}

    string public baseUri = "https://ipfs.io/ipfs/";

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function mint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId, uri);
    }

    function airdrop(address[] memory _tos, string memory _uri) public onlyOwner {
        for (uint8 i = 0; i < _tos.length; i++) {
            mint(_tos[i], _uri);
        }
    }
}