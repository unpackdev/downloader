//  ██▓     ██▓ ▄▄▄       ██▀███       ▄████  ▄▄▄       ███▄ ▄███▓▓█████ 
// ▓██▒    ▓██▒▒████▄    ▓██ ▒ ██▒    ██▒ ▀█▒▒████▄    ▓██▒▀█▀ ██▒▓█   ▀ 
// ▒██░    ▒██▒▒██  ▀█▄  ▓██ ░▄█ ▒   ▒██░▄▄▄░▒██  ▀█▄  ▓██    ▓██░▒███   
// ▒██░    ░██░░██▄▄▄▄██ ▒██▀▀█▄     ░▓█  ██▓░██▄▄▄▄██ ▒██    ▒██ ▒▓█  ▄ 
// ░██████▒░██░ ▓█   ▓██▒░██▓ ▒██▒   ░▒▓███▀▒ ▓█   ▓██▒▒██▒   ░██▒░▒████▒
// ░ ▒░▓  ░░▓   ▒▒   ▓▒█░░ ▒▓ ░▒▓░    ░▒   ▒  ▒▒   ▓▒█░░ ▒░   ░  ░░░ ▒░ ░
// ░ ░ ▒  ░ ▒ ░  ▒   ▒▒ ░  ░▒ ░ ▒░     ░   ░   ▒   ▒▒ ░░  ░      ░ ░ ░  ░
//   ░ ░    ▒ ░  ░   ▒     ░░   ░    ░ ░   ░   ░   ▒   ░      ░      ░   
//     ░  ░ ░        ░  ░   ░              ░       ░  ░       ░      ░  ░
                                                                      
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract Invitation is Ownable, ERC721A, ReentrancyGuard {
    constructor(
    ) ERC721A("Liar Game Pass", "LIARGAME", 5, 10000) {}

    //public sale
    bool public publicSaleStatus = false;
    uint256 public publicPrice = 0.0069 ether;
    uint256 public amountForPublicSale = 10000;
    uint256 public immutable publicSalePerMint = 5;
    uint256 public immutable publicSaleWalletLimit = 5;

    function publicSaleMint(uint256 quantity, string memory ownerName) external payable {
        require(
        publicSaleStatus,
        "public sale has not started yet"
        );
        require(
        totalSupply() + quantity <= collectionSize,
        "SOLD OUT"
        );
        require(
        amountForPublicSale >= quantity,
        "SOLD OUT"
        );

        require(
        quantity <= publicSalePerMint,
        "reached batch limit"
        );

        require(
        quantity + balanceOf(msg.sender) <= publicSaleWalletLimit,
        "reached wallet limit"
        );

        _safeMint(msg.sender, quantity, ownerName);

        amountForPublicSale -= quantity;
        refundIfOver(uint256(publicPrice) * quantity);
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSaleStatus = status;
    }

    function getPublicSaleStatus() external view returns(bool) {
        return publicSaleStatus;
    }

    function reserveMint(uint256 quantity, string memory ownerName) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "reached limit"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize, ownerName);
        }
        if (quantity % maxBatchSize != 0){
            _safeMint(msg.sender, quantity % maxBatchSize, ownerName);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
}