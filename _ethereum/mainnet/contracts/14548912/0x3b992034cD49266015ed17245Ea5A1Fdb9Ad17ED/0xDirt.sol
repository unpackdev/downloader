// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./console.sol";

contract OxDirt is Ownable, ERC721A, ReentrancyGuard {
    uint256 earlyMintCost = 1690000000000000;
    uint256 mintCost = 16900000000000000;
    uint256 collectionSize = 2500;
    uint256 earlyMintCount = 500;
    bool publicMintActive = false;
    address private paymentAddress = 0xf96d872eB87e0c75DB46a8764fa3B04179142658;
    address private paymentAddressDev = 0x55D47BfcBd2e3FD6a4fAE33510a9DbdB5030E764;

    constructor() ERC721A("0xDirt", "0xDirtNFT") {}

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

    function earlyPublicMint(uint256 quantity) external payable callerIsUser {
        require(quantity > 0);
        require(publicMintActive, "mint is not open at this time");
        require(
            totalSupply() + quantity <= earlyMintCount,
            "reached max supply of early mints, now youll have to pay up"
        );
        require(msg.value >= earlyMintCost * quantity, "not enough funds");

        _safeMint(msg.sender, quantity);
        refundIfOver(earlyMintCost * quantity);
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
        return _baseTokenURI;
    }

    function excavate() external onlyOwner nonReentrant {
        uint256 paymentDev = address(this).balance / 4;
        uint256 remainder = address(this).balance - paymentDev;

        Address.sendValue(payable(paymentAddressDev), paymentDev);
        Address.sendValue(payable(paymentAddress), remainder);
    }
}
