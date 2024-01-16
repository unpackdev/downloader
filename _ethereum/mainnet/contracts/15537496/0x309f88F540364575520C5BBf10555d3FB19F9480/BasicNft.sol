// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC721.sol";

contract EthereumMergePanda is ERC721 {
    string public constant TOKEN_URI = "ipfs://QmPhd6W8bpqmN1147xarhyr21TZs39RQoYPASaZ9sV3y4R";
    uint256 private s_tokenCounter;

    constructor() ERC721("Ethereum Merge Panda", "EMP") {
        s_tokenCounter = 0;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
    }

    function tokenURI(
        uint256 /*tokenId*/
    ) public view override returns (string memory) {
        return TOKEN_URI;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
