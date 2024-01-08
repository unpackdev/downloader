// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract Explorer is ERC721URIStorage, Ownable {
    constructor() ERC721('The Exploration Project', 'TEP') {}

    function mintBatch (
        address to,
        uint256[] memory tokenIds,
        string[] memory tokenURIs
    ) public onlyOwner {
        require(tokenIds.length == tokenURIs.length, 'Incorrect quantities given.');

        for (uint i = 0; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i]);
            _setTokenURI(tokenIds[i], tokenURIs[i]);
        }
    }

    function updateTokenURI (
        uint256 tokenId,
        string memory tokenURI
    ) public onlyOwner {
        _setTokenURI(tokenId, tokenURI);
    }
}
