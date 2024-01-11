/*
Baby Trippin' Ape Tribe
Twitter: https://twitter.com/BabyTATribe
Discord: https://discord.com/invite/amZZCPjj3U
500 free mints
2500 mints at 0.005 eth
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./Ownable.sol";
import "./ERC721A.sol";


contract BabyTrippinApeTribe is ERC721A, Ownable {
    bool public SaleIsActive;

    uint8 public constant MaxPerTransaction = 10;
    uint16 public constant MaxFreeTokens = 600;
    uint16 public constant Reserved = 100;
    uint16 public constant MaxTokens = 3000;
    uint16 public constant MaxPublicSupply = MaxTokens - Reserved;
    uint256 public TokenPrice = 0.005 ether;

    string private _baseTokenURI;
    
    constructor(string memory baseURI) ERC721A("Baby Trippin Ape Tribe", "TRIP", MaxPerTransaction, MaxTokens) {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function mint(uint256 numTokens) external payable {
        require(SaleIsActive, "Sale must be active in order to mint");
        require(numTokens <= MaxPerTransaction, "Higher than max per transaction");
        require(totalSupply() + numTokens <= MaxPublicSupply, "Purchase more than max supply");

        if (totalSupply() >= MaxFreeTokens) require(msg.value >= numTokens * TokenPrice, "Ether too low");
            
        _safeMint(_msgSender(), numTokens);
    }

    function claimReserves(uint256 numTokens) external onlyOwner {
        require(totalSupply() >= MaxPublicSupply);
        require(totalSupply() + numTokens < MaxTokens);
        _safeMint(_msgSender(), numTokens, false, "");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function toggleSaleState() external onlyOwner {
        SaleIsActive = !SaleIsActive;
    }

    function setTokenPrice(uint256 tokenPrice) external onlyOwner {
        TokenPrice = tokenPrice;
    }
           
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}