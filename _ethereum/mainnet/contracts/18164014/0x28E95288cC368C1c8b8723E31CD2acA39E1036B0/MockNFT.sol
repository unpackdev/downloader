// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";

contract MockNFT is ERC721 {
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}