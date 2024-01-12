// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721A.sol";

import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract RadiantEnclaveGenesis is ERC721A, Ownable, Pausable, ReentrancyGuard {

    string public baseTokenURI = "https://ipfs.io/ipfs/QmTdtqTFKLS3m9dWCyEuu5b5iKasND3CfENbGBs8vm4Gei/";
    
    constructor() ERC721A("RadiantEnclaveGenesis", "Elders") { 
        _mint(0xD67F39F0706219607c00f1dF41bE37ABDEA6c31a, 30);
    } 


    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        string memory uri = string(abi.encodePacked(baseURI, _toString(tokenId)));
        string memory fullUri = string(abi.encodePacked(uri, ".json"));
        return bytes(baseURI).length != 0 ? fullUri : '';
    }
}
