// SPDX-License-Identifier: MIT

/***
 ________ ________  _______   _______   ___       ___  _________  _________  ___       _______   ________  ___  ________  ________      
|\  _____\\   __  \|\  ___ \ |\  ___ \ |\  \     |\  \|\___   ___\\___   ___\\  \     |\  ___ \ |\   __  \|\  \|\   ____\|\   ____\     
\ \  \__/\ \  \|\  \ \   __/|\ \   __/|\ \  \    \ \  \|___ \  \_\|___ \  \_\ \  \    \ \   __/|\ \  \|\  \ \  \ \  \___|\ \  \___|_    
 \ \   __\\ \   _  _\ \  \_|/_\ \  \_|/_\ \  \    \ \  \   \ \  \     \ \  \ \ \  \    \ \  \_|/_\ \   ____\ \  \ \  \  __\ \_____  \   
  \ \  \_| \ \  \\  \\ \  \_|\ \ \  \_|\ \ \  \____\ \  \   \ \  \     \ \  \ \ \  \____\ \  \_|\ \ \  \___|\ \  \ \  \|\  \|____|\  \  
   \ \__\   \ \__\\ _\\ \_______\ \_______\ \_______\ \__\   \ \__\     \ \__\ \ \_______\ \_______\ \__\    \ \__\ \_______\____\_\  \ 
    \|__|    \|__|\|__|\|_______|\|_______|\|_______|\|__|    \|__|      \|__|  \|_______|\|_______|\|__|     \|__|\|_______|\_________\
                                                                                                                            \|_________|
 */

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract FreeLittlePigs is Ownable, ERC721A {
    using Strings for uint256;

    bool public revealed;
    bool public isSalesActive;
    uint256 public collectionSize = 3000;
    uint256 public freeAmount = 1000;
    uint256 public maxBatchSize = 5;
    uint256 public salesPrice = 0.002 ether;
    string private baseTokenURI;

    constructor(string memory _baseTokenURI) ERC721A("FreeLittlePigs", "FLIP") {
        baseTokenURI = _baseTokenURI;
    }

    modifier noContract() {
        require(tx.origin == msg.sender, "No Contract call!");
        _;
    }

    function devMint(uint256 quantity) external onlyOwner {
        super._safeMint(msg.sender, quantity);
    }

    function setPrice(uint256 _price) external onlyOwner {
        salesPrice = _price;
    }

    function startSales() external onlyOwner {
        isSalesActive = true;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }

    function safeCum69420(uint256 quantity) external payable noContract {
        require(isSalesActive, "Sales are not active!");
        require(
            quantity <= maxBatchSize,
            "Quantity must be less than or equal to maxBatchSize!"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "Max supply is reached!"
        );

        if (totalSupply() + quantity <= freeAmount) {
            super._safeMint(msg.sender, quantity);
        } else {
            require(msg.value >= salesPrice * quantity, "Not enough ETH!");
            super._safeMint(msg.sender, quantity);
        }
    }

    function setReveal(bool _reveal) external onlyOwner {
        revealed = _reveal;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            revealed
                ? string(abi.encodePacked(baseTokenURI, tokenId.toString()))
                : baseTokenURI;
    }

    function withdraw(address _address) external onlyOwner {
        payable(_address).transfer(address(this).balance);
    }
}
