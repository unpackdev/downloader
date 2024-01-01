// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract HoodyGenesis is ERC721Enumerable, Ownable {
    mapping(uint256 => string) private tokenURIs;

    constructor() ERC721("HoodyGang OG 1/1s", "HGO") Ownable(msg.sender) {}

    function mint(string memory _uri, address _receiver) external onlyOwner {
        uint256 tokenId = totalSupply() + 1;
        _mint(_receiver, tokenId);
        tokenURIs[tokenId] = _uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return tokenURIs[tokenId];
    }
}
