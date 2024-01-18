// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

/// @custom:security-contact info@hivearium.art
contract CosmicWings is ERC721, Ownable {
    constructor() ERC721("Cosmic Wings", "COWI") {}

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        require(
            tokenId == 1,
            "This contract has only one valid ID and it's 1."
        );
        return "ipfs://QmQqhKizQvkA8hE6Gq8iRyjDGDE4uwyWmvZkLPjeKQ1fsq";
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, 1);
    }
}
