// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./console.sol";

contract OxOkayBears is Ownable, ERC721A, ReentrancyGuard {
    uint256 mintCost = 3690000000000000;
    uint256 collectionSize = 3500;
    bool publicMintActive = false;
    address private paymentAddress;

    constructor(address paymentAddress_) ERC721A("0xOkayBears", "0xOkayBears") {
        paymentAddress = paymentAddress_;
    }

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

    function setMintCost(uint256 cost) external onlyOwner {
        mintCost = cost;
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

        string memory metadataString;

        if (tokenId % 10 == 0) {
            metadataString = string(abi.encodePacked(_baseTokenURI, "/", "9", ".json"));
        }
        else if (tokenId % 9 == 0) {
            metadataString = string(abi.encodePacked(_baseTokenURI, "/", "8", ".json"));
        }
        else if (tokenId % 8 == 0) {
            metadataString = string(abi.encodePacked(_baseTokenURI, "/", "7", ".json"));
        }
        else if (tokenId % 7 == 0) {
            metadataString = string(abi.encodePacked(_baseTokenURI, "/", "6", ".json"));
        }
        else if (tokenId % 6 == 0) {
            metadataString = string(abi.encodePacked(_baseTokenURI, "/", "5", ".json"));
        }
        else if (tokenId % 5 == 0) {
            metadataString = string(abi.encodePacked(_baseTokenURI, "/", "4", ".json"));
        }
        else if (tokenId % 4 == 0) {
            metadataString = string(abi.encodePacked(_baseTokenURI, "/", "3", ".json"));
        }
        else if (tokenId % 3 == 0) {
            metadataString = string(abi.encodePacked(_baseTokenURI, "/", "2", ".json"));
        }
        else if (tokenId % 2 == 0) {
            metadataString = string(abi.encodePacked(_baseTokenURI, "/", "1", ".json"));
        }
        else {
            metadataString = string(abi.encodePacked(_baseTokenURI, "/", "0", ".json"));
        }
        return metadataString;
    }

    function distributeFunds() external onlyOwner nonReentrant {
        Address.sendValue(payable(paymentAddress), address(this).balance);
    }
}
