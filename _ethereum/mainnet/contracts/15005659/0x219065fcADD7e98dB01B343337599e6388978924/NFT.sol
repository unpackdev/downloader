// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC721CrossChain.sol";

contract NFT is Ownable, ERC721CrossChain {
    uint256 public nextTokenId = 0;
    string public defaultURI;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721CrossChain(name, symbol) {}

    function mint(uint256 quantity) public {
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(_msgSender(), nextTokenId++);
        }
    }

    function setDefaultURI(string memory uri) public onlyOwner {
        defaultURI = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return defaultURI;
    }
}