// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Eigenapes is ERC721, Ownable {
    using Counters for Counters.Counter;

    string constant BASE_URI = "ipfs://QmQ8oBNtMuMzHxbgh9gPEHtLUaQZzVCuNJpWBjC7oJivYq/";
    uint constant INIT_TOKENS = 10;
    uint constant MAX_TOKENS = 400;
    uint constant MAX_MINT = 20;

    Counters.Counter private _nextIdCounter;

    constructor() ERC721("Eigenapes", "EAPE") {
        mintToken(INIT_TOKENS);
    }

    function _baseURI() internal pure override returns (string memory) {
        return BASE_URI;
    }

    function mintToken(uint num) public onlyOwner {
        require(num <= MAX_MINT, "Cannot mint more than 10 tokens at a time.");
        require((_nextIdCounter.current() + num) <= MAX_TOKENS, "Cannot exceed 400 total tokens.");

        for (uint i = 0; i < num; i++) {
            uint256 nextId = _nextIdCounter.current();
            _safeMint(msg.sender, nextId);
            _nextIdCounter.increment();
        }
    }
}