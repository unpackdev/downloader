// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721PresetMinterPauserAutoId.sol";

contract FlokiInuNFTReward is ERC721PresetMinterPauserAutoId {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    )
    ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI)
    {

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _baseURI();
    }
}
