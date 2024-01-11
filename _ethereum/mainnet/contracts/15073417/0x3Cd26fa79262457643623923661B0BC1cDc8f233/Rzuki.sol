// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract Rzuki is Ownable, ERC721A, ReentrancyGuard {
    //name，symbol，maxBatchSize，collectionSize
    constructor(string memory initBaseURI) ERC721A("Rzuki", "RZK", 10, 1888) {
        baseTokenURI = initBaseURI;
    }

    // metadata URI
    string public baseTokenURI;

    function _baseURI() internal view virtual override returns(string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }


    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call {
            value: address(this).balance}("");
            require(success, "Transfer failed.");
        }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }


    function numberMinted(address owner) public view returns(uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns(TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // For marketing etc.
    function airdrop(uint256 quantity, address to) external onlyOwner {
        require(totalSupply() + quantity <= collectionSize,"too many already minted before dev mint");
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(to, maxBatchSize);
        }
        if (quantity % maxBatchSize != 0) {
            _safeMint(to, quantity % maxBatchSize);
        }
    }

    //-----------publicSaleMint------------------------
    bool public publicSaleStatus = false;
    uint256 public publicPrice = 0.006900 ether;
    uint256 public amountForPublicSale = 1000;
    uint256 public immutable publicSalePerMint = 5;

    function setPublicSaleStatus(bool newPublicSaleStatus) external onlyOwner {
        publicSaleStatus = newPublicSaleStatus;
    }

    function setPublicPrice(uint256 newPublicPrice) external onlyOwner {
        require(newPublicPrice >= 0, "Public price must be greater than zero");
        publicPrice = newPublicPrice;
    }

    function publicSaleMint(uint256 quantity) external payable {
        require(publicSaleStatus, "not begun");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(amountForPublicSale >= quantity, "reached max amount");
        require(quantity <= publicSalePerMint, "reached max amount per mint");
        _safeMint(msg.sender, quantity);
        amountForPublicSale -= quantity;
        refundIfOver(uint256(publicPrice) * quantity);
    }



    //-----------FreeMint------------------------
    bool public freeMintStatus = false;
    uint256 public freeMintAmount = 858;
    uint256 public immutable maxFreeMint = 2;

    function setFreeMintStatus(bool newFreeMintStatus) external onlyOwner {
        freeMintStatus = newFreeMintStatus;
    }

    mapping(address => uint256) public freeStock;
    mapping(address => bool) public freeAppeared;
    function freeMint(uint256 quantity) external payable {
        require(freeMintStatus, "not begun");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(freeMintAmount >= quantity, "reached max amount");
        require(quantity <= maxFreeMint, "reached max amount per mint");
        if (!freeAppeared[msg.sender]) {
            freeAppeared[msg.sender] = true;
            freeStock[msg.sender] = maxFreeMint;
        }
        require(freeStock[msg.sender] >= quantity, "reached free per address mint amount");
        freeStock[msg.sender] -= quantity;
        _safeMint(msg.sender, quantity);
        freeMintAmount -= quantity;
    }
}