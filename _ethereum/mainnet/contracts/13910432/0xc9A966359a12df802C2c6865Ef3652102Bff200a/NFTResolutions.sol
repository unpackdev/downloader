//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract NFTResolutions is ERC721, Ownable {
    uint public constant ethCost = 0.01 ether;
    uint256 public tokenCounter;
    
    constructor() public ERC721("NFT Resolution", "NFTR") {
        tokenCounter = 0;
    }
    function mintResolution(string memory tokenURI) public payable returns (uint256) {
        require(tokenCounter + 1 <= 2022, "Not enough NFTs left!");
        require(msg.value >= ethCost, "Insufficient funds!");

        uint256 newItemId = tokenCounter;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        tokenCounter = tokenCounter + 1;
        return newItemId;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}