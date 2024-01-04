// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721.sol";

contract TAEY is ERC721 {
    constructor() ERC721("This Artwork Earns Yield", "TAEY") {
        _mint(msg.sender, 13);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://thisartworkearnsyield.com/api/";
    }
}
