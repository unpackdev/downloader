// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "ERC721.sol";

contract AdvancedCollectible is ERC721 {
    uint256 public tokenCounter;
    enum Breed {
        DAXIONG,
        PANGHU,
        XIAOFU
    }
    mapping(uint256 => Breed) public tokenIdToBreed;
    event breedAssigned(uint256 indexed tokenId, Breed breed);

    constructor() public ERC721("Doraemon", "DOR") {
        tokenCounter = 0;
    }

    function createCollectible() public returns (bytes32) {
        Breed breed = Breed(tokenCounter % 3);
        uint256 newTokenId = tokenCounter;
        tokenIdToBreed[newTokenId] = breed;
        emit breedAssigned(newTokenId, breed);
        _safeMint(msg.sender, newTokenId);
        tokenCounter = tokenCounter + 1;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not owner no approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }
}
