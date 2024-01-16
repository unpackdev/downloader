// SPDX-License-Identifier: MIT

/**
                               _
     /\                       | |
    /  \   _ __ ___   __ _  __| | ___ _   _ ___
   / /\ \ | '_ ` _ \ / _` |/ _` |/ _ | | | / __|
  / ____ \| | | | | | (_| | (_| |  __| |_| \__ \
 /_/    \_|_| |_| |_|\__,_|\__,_|\___|\__,_|___/

 @powered by: amadeus-nft.io
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract KidsX is Ownable, ERC721A, ReentrancyGuard {
    address private amadeusAddress = 0x718a7438297Ac14382F25802bb18422A4DadD31b;

    constructor() ERC721A("kids x", "KIDSX") {
        _safeMint(amadeusAddress, 25);
    }

    uint256 public collectionSize = 1000;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // For marketing etc.
    function reserveMintBatch(uint256[] calldata quantities, address[] calldata tos) external onlyOwner {
        for(uint256 i = 0; i < quantities.length; i++){
            require(
                totalSupply() + quantities[i] <= collectionSize,
                "Too many already minted before dev mint."
            );
            _safeMint(tos[i], quantities[i]);
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

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
    //public sale
    bool public publicSaleStatus = false;
    uint256 public publicPrice = 0.000000 ether;
    uint256 public amountForPublicSale = 975;
    // per address public sale limitation
    mapping(address => uint256) private publicSaleMintedPerAddress;
    uint256 public immutable publicSalePerAddress = 2;

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        require(publicSaleStatus, "not begun");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(amountForPublicSale >= quantity, "reached max amount");

        require(publicSaleMintedPerAddress[msg.sender] + quantity <= publicSalePerAddress, "reached max amount per address");

        _safeMint(msg.sender, quantity);
        amountForPublicSale -= quantity;
        publicSaleMintedPerAddress[msg.sender] += quantity;
        refundIfOver(uint256(publicPrice) * quantity);
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSaleStatus = status;
    }
}