// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("MOCK", "MOCK") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
