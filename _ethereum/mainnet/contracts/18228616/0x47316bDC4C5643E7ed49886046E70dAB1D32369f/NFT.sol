// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter internal _tokenIdCounter;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {}

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
    }
}
