// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC721A.sol";

contract UdoDrop is ERC721A {
    string private baseURI;

    constructor(string memory inputURI) ERC721A("Udo", "UDO") {
        _mint(msg.sender, 3);
        baseURI = inputURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}