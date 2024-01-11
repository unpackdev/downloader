// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721Opensea.sol";

contract MindblowonHonorary is ERC721Opensea {
    constructor() ERC721("Mindblowon Honoraries", "MB-HONORARY") {}

    function gift(address[] calldata receivers) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
}
