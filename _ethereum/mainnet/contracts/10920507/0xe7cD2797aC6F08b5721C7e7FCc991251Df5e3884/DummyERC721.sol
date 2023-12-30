// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC721.sol";

contract DummyVanillaERC721 is ERC721 {
    string public constant NAME = "Vanilla ERC721";
    string public constant SYMBOL = "VANILLA-";

    constructor() public ERC721(NAME, SYMBOL) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
