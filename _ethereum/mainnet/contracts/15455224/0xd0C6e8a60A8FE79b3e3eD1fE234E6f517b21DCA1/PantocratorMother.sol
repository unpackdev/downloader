// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

/// @custom:security-contact info@hivearium.art
contract PantocratorMother is ERC721, Ownable {
    constructor() ERC721("Pantocrator Mother", "PAMO") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmZXR9YorMivJ5mYjE56oqJNj2bw1gEPKnumWpK8hoMAdz";
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, 1);
    }
}
