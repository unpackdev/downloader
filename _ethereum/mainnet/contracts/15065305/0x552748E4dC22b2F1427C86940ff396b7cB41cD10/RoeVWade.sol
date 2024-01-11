// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./console.sol";

contract RoeVWade is Ownable, ERC721A, ReentrancyGuard {
    uint256 mintCost = 30000000000000000;
    uint256 collectionSize = 3333;
    bool publicMintActive = false;
    address private paymentAddress;

    constructor(address paymentAddress_) ERC721A("RoeVWade", "RoeVWade") {
        paymentAddress = paymentAddress_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function ownerMint(uint256 quantity) external payable callerIsUser {
        require(quantity > 0);
        require(msg.sender == paymentAddress, "not an owner");

        _safeMint(msg.sender, quantity);
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
        return _baseTokenURI;
    }

    function unburden() external onlyOwner nonReentrant {
        Address.sendValue(payable(paymentAddress), address(this).balance);
    }
}
