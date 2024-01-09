// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";

contract NFT is ERC721URIStorage {
    constructor() ERC721("gnidan and Piper the Cat", "GNDP") {
        _mint(msg.sender, 0);
        _setTokenURI(0, "ipfs://QmWV3QfhJBKJj77a4h1HszEEaZmtyDkBHsTz38eNMuTRxH");
    }
}