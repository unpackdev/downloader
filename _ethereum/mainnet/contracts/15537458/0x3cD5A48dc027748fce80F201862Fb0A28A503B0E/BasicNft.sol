// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC721.sol";

contract MergePanda is ERC721 {
    string public constant TOKEN_URI =
        "ipfs://bafybeiafqb4x3llqdav4podkkqn2bupq7l24babnj4igxidu23tiebrhum/";
    uint256 private s_tokenCounter;

    constructor() ERC721("Merge Panda", "mPND") {
        s_tokenCounter = 0;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return TOKEN_URI;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
