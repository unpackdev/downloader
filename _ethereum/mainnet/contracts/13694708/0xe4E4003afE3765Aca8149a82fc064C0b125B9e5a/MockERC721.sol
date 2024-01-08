// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ERC721.sol";

contract MockERC721 is ERC721 {

    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }

    function testMint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
