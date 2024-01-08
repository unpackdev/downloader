// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";

import "./OnChainSweatersTypes.sol";


contract OnChainSweatersRendererPrereveal is Ownable {
    string private _tokenUri;

    constructor()  {
        _tokenUri = '{"name": "On Chain Christmas Sweater", "description": "The First, 100% On-Chain Christmas Sweater patterns generator with real world utility! More info on our web page:  sweatersonchain.com", "image": "https://sweatersonchain.s3.amazonaws.com/pre-reveal/pre-reveal-thumbnail.gif"}';
    }

    function updateTokenUriContent(string calldata content) public onlyOwner {
        _tokenUri = content;
    }

    function tokenURI(uint256 tokenId, OnChainSweatersTypes.OnChainSweater memory sweater) external view returns (string memory) {
        return _tokenUri;
    }

    function getHQClaimedSweater(uint256 tokenId, OnChainSweatersTypes.OnChainSweater memory sweater, address tx) external view returns (string memory) {
        return '{"error": "Not available. This is pre-reveal."}';
    }
}
