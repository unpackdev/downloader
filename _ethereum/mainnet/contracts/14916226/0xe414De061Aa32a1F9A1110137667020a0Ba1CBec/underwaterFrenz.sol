// SPDX-License-Identifier: MIT

/***
Underwater Frenz
***/
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";

contract UnderwaterFrenz is ERC721A, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint8 public constant freePerWallet = 2;
    uint8 public constant transactionLimit = 5;
    uint8 public constant walletLimit = 10;
    
    bool private isSale = false;
    bool private isReveal = false;
    uint32 public totalFreeMinted = 0;
    uint32 public reservedNFTsAmount;

    string private baseURI;

    uint16 public constant totalNFTs = 10000;
    uint16 private constant basicNFTs = 9850;
    uint16 private constant reservedNFTs = 150;
    uint16 private constant instantFreeLimit = 5000;

    uint256 public nftPrice = 0.005 ether;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {
        reservedNFTsAmount = 0;
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    function setReveal(bool reveal) external onlyOwner {
        isReveal = reveal;
    }

    
    function isSaleOn(bool status) external onlyOwner {
        isSale = status;
    }

    function mint(
        uint8 amount
    ) public payable {
        require(isSale, "Sale has not been started");
        require(tx.origin == msg.sender, "Underwater Frenz: Caller must be an account");
        require(amount <= transactionLimit,"Underwater Frenz: Max transaction is 5");        
        require(totalSupply() + amount <= totalNFTs, "Underwater Frenz: Max total supply is exceeded");

        uint32 minted = uint32(_numberMinted(msg.sender));
        require(amount + minted <= walletLimit, "Underwater Frenz: Wallet limit is exceeded");

        uint32 freeAmount = 0;
         if (minted < freePerWallet && totalFreeMinted < instantFreeLimit ) {
            uint32 freeLeft = freePerWallet - minted;
            freeAmount += freeLeft > amount ? amount : freeLeft;
            freeAmount = totalFreeMinted + freeAmount >= instantFreeLimit ? 1 : freePerWallet;
            totalFreeMinted = totalFreeMinted + freeAmount;
        }

        uint256 requiredValue = (amount - freeAmount) * nftPrice;
        require(msg.value >= requiredValue, "Underwater Frenz: Insufficient fund");

        _safeMint(msg.sender, amount);
        if (msg.value > requiredValue) {
            payable(msg.sender).sendValue(msg.value - requiredValue);
        }
    }

    function reserveNFT(address to, uint16 amount) public onlyOwner {
        require(reservedNFTsAmount + amount <= reservedNFTs, "Underwater Frenz: Out of stock");

        _safeMint(to, amount);
        reservedNFTsAmount += amount;
    }

    function setNFTPrice(uint256 price) public onlyOwner {
        nftPrice = price;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return isReveal ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : baseURI;
    }

}