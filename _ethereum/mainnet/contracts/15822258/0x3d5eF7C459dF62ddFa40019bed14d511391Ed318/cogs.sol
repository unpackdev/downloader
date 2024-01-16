// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Cogs is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _cogCounter;

    constructor() ERC721("Cogs", "COG") {
        _cogCounter.increment();  // first token is 1
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmNwBxJ9xS2TXLeG6ALYn1iML1CFfGzPgLKnBJPS27TRqj/";
    }

    function safeMint(address to) public onlyOwner {
        uint256 cogId = _cogCounter.current();
        require(cogId <= 12, "exceeded max supply");  // limit to 12 
        _cogCounter.increment();
        _safeMint(to, cogId);
    }
}