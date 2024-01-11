// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "ERC721URIStorage.sol";
import "Ownable.sol";
import "Counters.sol";

contract PhotographyNFT is ERC721URIStorage, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter public currentTokenId;
    mapping(uint256 => string) public tokenIdToName;
    event CreatedPhotographyNFT(uint256 newItemId); 
    
    constructor() public ERC721("FCPhotographyNFT", "FCP") {
    }

    function createCollectible(string memory name, string memory tokenURI) public onlyOwner {
        address photoOwner = msg.sender;
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        tokenIdToName[newItemId] = name;
        _safeMint(photoOwner, newItemId);
        _setTokenURI(newItemId, tokenURI);
        emit CreatedPhotographyNFT(newItemId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

}
