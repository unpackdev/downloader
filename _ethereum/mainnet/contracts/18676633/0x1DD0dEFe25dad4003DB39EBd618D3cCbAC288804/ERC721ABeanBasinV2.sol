// SPDX-License-Identifier: MIT
// Code adopted and modified from:
// Chiru labs: ERC721AUpgradable v4.2.3

pragma solidity ^0.8.20;

import "./ERC721ABeanBasin.sol";

contract ERC721ABeanBasinV2 is ERC721ABeanBasin {

    // Store uris in state in case a modification is needed
    string public baseUri;
    string public upgradedBaseUri;

    /**
     * @dev Set the IPFS baseUri for the initial nfts.
     * @param _baseUri The baseUri to be set.
     */
    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /**
     * @dev Set the IPFS upgradedBaseUri for the upgraded nfts.
     * @param _upgradedBaseUri The upgraded uri to be set.
     */
    function setUpgradedBaseUri(string memory _upgradedBaseUri) public onlyOwner {
        upgradedBaseUri = _upgradedBaseUri;
    }

    /**
     * @dev Returns the baseUri for the initial nfts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    /**
     * @dev Returns the upgradedBaseUri for the upgraded nfts.
     */
    function _upgradedBaseURI() internal view virtual override returns (string memory) {
        return upgradedBaseUri;
    }

}