// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ERC721.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Controlled.sol";


contract SuperBidNFT is Ownable, Controlled, ERC721, ReentrancyGuard {
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}
    mapping (uint256 => string) tokenIdToUrl;

    function mint(uint256 _id, address _owner, string memory url) external onlyController nonReentrant {
        require(!_exists(_id), "SuperBidNFT: token already exists");

        tokenIdToUrl[_id] = url;
        _safeMint(_owner, _id);
    }

    // NFT Standard
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenIdToUrl[tokenId];
    }
}