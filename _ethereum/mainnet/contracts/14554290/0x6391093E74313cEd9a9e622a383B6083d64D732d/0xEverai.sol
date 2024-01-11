// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./console.sol";

contract OxEverai is Ownable, ERC721A, ReentrancyGuard {
    uint256 mintCost = 3000000000000000;
    uint256 collectionSize = 7777;
    bool publicMintActive = false;
    address private paymentAddress = 0xf96d872eB87e0c75DB46a8764fa3B04179142658;
    address private paymentAddressDev = 0x55D47BfcBd2e3FD6a4fAE33510a9DbdB5030E764;

    constructor() ERC721A("0xEverai", "0xEveraiNFT") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setPublicMintActive(bool isMintActive) public onlyOwner {
        publicMintActive = isMintActive;
    }

    function isPublicMintActive() public view returns (bool) {
        return publicMintActive;
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(quantity > 0);
        require(publicMintActive, "mint is not open at this time");
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(msg.value >= mintCost * quantity, "not enough funds");

        _safeMint(msg.sender, quantity);
        refundIfOver(mintCost * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory returnString;

        if (tokenId % 9 == 0) {
            returnString = string(abi.encodePacked(_baseTokenURI, "/", "9", ".json"));
        }
        else if (tokenId % 8 == 0) {
            returnString = string(abi.encodePacked(_baseTokenURI, "/", "8", ".json"));
        }
        else if (tokenId % 7 == 0) {
            returnString = string(abi.encodePacked(_baseTokenURI, "/", "7", ".json"));
        }
        else if (tokenId % 6 == 0) {
            returnString = string(abi.encodePacked(_baseTokenURI, "/", "6", ".json"));
        }
        else if (tokenId % 5 == 0) {
            returnString = string(abi.encodePacked(_baseTokenURI, "/", "5", ".json"));
        }
        else if (tokenId % 4 == 0) {
            returnString = string(abi.encodePacked(_baseTokenURI, "/", "4", ".json"));
        }
        else if (tokenId % 3 == 0) {
            returnString = string(abi.encodePacked(_baseTokenURI, "/", "3", ".json"));
        }
        else if (tokenId % 2 == 0) {
            returnString = string(abi.encodePacked(_baseTokenURI, "/", "2", ".json"));
        }
        else if (tokenId % 1 == 0) {
            returnString = string(abi.encodePacked(_baseTokenURI, "/", "1", ".json"));
        }
        else {
            returnString = string(abi.encodePacked(_baseTokenURI, "/", "0", ".json"));
        }

        return returnString;
    }

    function distributeFunds() external onlyOwner nonReentrant {
        uint256 paymentDev = address(this).balance / 3;
        uint256 remainder = address(this).balance - paymentDev;

        Address.sendValue(payable(paymentAddressDev), paymentDev);
        Address.sendValue(payable(paymentAddress), remainder);
    }
}
