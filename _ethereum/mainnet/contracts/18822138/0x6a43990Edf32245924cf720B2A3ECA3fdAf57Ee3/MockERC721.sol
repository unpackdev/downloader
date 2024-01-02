// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "./ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("MockERC721", "M721") {}

    function mint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }
}
