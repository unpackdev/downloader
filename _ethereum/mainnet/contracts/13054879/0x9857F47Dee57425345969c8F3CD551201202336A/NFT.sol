// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./ERC721.sol";

contract NFT is ERC721URIStorage {
    address public owner;
    uint256 public tokenCap;

    constructor() ERC721("HUNMINJEONGEUM HAERYEBON", "HMJE") {
        owner = msg.sender;
        tokenCap = 100;
    }

    function createToken(address account, uint256 tokenId, string memory tokenURI) public returns (uint) {
        require(msg.sender == owner, "NFT : only owner can create NFT");
        require(tokenId != 0, "NFT : tokenId starts 1");
        require(tokenId <= tokenCap, "NFT : too many token. tokenCap is 100");

        _mint(account, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

    function burnToken(uint256 tokenId) public returns (uint) {
        require(msg.sender == ownerOf(tokenId), "NFT : cannot burn other's token");
        _burn(tokenId);
        return tokenId;
    }

}