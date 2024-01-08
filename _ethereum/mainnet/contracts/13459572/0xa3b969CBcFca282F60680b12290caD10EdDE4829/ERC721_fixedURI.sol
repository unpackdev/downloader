// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";

contract ERC721_fixedURI is ERC721PresetMinterPauserAutoId {
    using Strings for uint256;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
        ) ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI){}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),"/metadata.json")) : "";
    }
}