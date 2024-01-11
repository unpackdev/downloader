//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./console.sol";

contract BadNFT is ERC721 {
    address private _owner;
    string private baseURI;

    constructor() ERC721("Buero am Draht", "BAD") {
        _owner = msg.sender;
        _safeMint(msg.sender, 1);
    }

    function setBaseURI(string memory uri) public {
        require(msg.sender == _owner, "You are not the owner");
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}