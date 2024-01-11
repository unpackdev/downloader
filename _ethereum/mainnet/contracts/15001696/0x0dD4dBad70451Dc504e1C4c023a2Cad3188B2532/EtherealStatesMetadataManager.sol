// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./Strings.sol";

contract EtherealStatesMetadataManager is Ownable {
    string public baseURI;
    bool public revealed;

    constructor(string memory baseURI_) {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory uri) {
        // if unrevealed, the baseURI is the same for all
        if (!revealed) {
            uri = baseURI;
        } else {
            uri = string.concat(baseURI, Strings.toString(tokenId), '.json');
        }
    }

    function setRevealed(bool isRevealed, string calldata newBaseURI)
        external
        onlyOwner
    {
        revealed = isRevealed;
        baseURI = newBaseURI;
    }
}
