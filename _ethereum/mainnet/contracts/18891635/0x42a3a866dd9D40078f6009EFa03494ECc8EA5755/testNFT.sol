// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract TestNft is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyToken", "MTK") {}

    function testMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    //Below functions are purely for testing purpose to mock gnosis safe
    mapping(address => bool) private _isOwner;

    function setupOwners(address owner) external {
        _isOwner[owner] = true;
    }

    function isOwner(address owner) public view returns (bool) {
        return _isOwner[owner];
    }
}
