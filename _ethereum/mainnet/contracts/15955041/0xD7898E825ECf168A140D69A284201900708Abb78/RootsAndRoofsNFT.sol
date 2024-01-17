// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ERC721.sol";
import "./Ownable.sol";

contract RootsAndRoofsNFT is ERC721, Ownable {
    constructor(address owner_) ERC721("Roots&Roofs G.ART Berlin Collection", "GART R&R") {
        for(uint8 i = 1; i < 30; i++) {
            _mint(owner_, i);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return "ipfs://QmUsRYu114FBg19wLKV5VGyLkVUoEjFC55W3sghWCAKMYe/";
    }
}
