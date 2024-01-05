// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC721Burnable.sol";
import "./ERC721PresetMinterPauserAutoId.sol";

contract NFT is ERC721PresetMinterPauserAutoId {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI) {}
}
