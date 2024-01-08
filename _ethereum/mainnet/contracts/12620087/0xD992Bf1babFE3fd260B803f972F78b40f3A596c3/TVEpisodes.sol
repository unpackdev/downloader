// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract TVEpisodes is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private _baseURIextended;

    constructor() ERC721("TVEpisodes", "TV") {}

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function batchMint(uint num, address to) public onlyOwner {
        for (uint i = 0; i < num; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function updateBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }
}