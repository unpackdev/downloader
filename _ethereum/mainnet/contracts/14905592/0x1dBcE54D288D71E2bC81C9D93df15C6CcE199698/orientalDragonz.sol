// SPDX-License-Identifier: MIT

/***
Oriental Dragonz
***/
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";

contract OrientalDRagonz is ERC721A, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint8 public constant freeLimitPerWallet = 2;
    uint8 public constant maxPerTransaction = 5;
    uint8 public constant maxPerWallet = 5;
    bool private saleOn = false;

    uint16 public reservedNFTsAmount;

    string private baseURI;

    uint16 public constant totalNFTs = 5000;
    uint16 private constant basicNFTs = 4850;
    uint16 private constant reservedNFTs = 150;

    uint256 public nftPrice = 0.007 ether;

    struct Status {
        uint32 userMinted;
    }

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

    function mint(
        uint8 amount
    ) public payable {
        require(saleOn, "Sale has not been started");
        require(amount <= maxPerTransaction,"Oriental Dragonz: Cannot mint more than 5 in a single transaction");
        require(tx.origin == msg.sender, "Oriental Dragonz: Caller must be an account");

        uint32 minted = uint32(_numberMinted(msg.sender));
        require(amount + minted <= maxPerWallet, "Oriental DRagonz: Exceed wallet limit");

        uint32 freeAmount = 0;
         if (minted < freeLimitPerWallet) {
            uint32 freeLeft = freeLimitPerWallet - minted;
            freeAmount += freeLeft > amount ? amount : freeLeft;
        }

        uint256 requiredValue = (amount - freeAmount) * nftPrice;
        require(msg.value >= requiredValue, "Oriental Dragonz: Insufficient fund");

        _safeMint(msg.sender, amount);
        if (msg.value > requiredValue) {
            payable(msg.sender).sendValue(msg.value - requiredValue);
        }
    }

    function userMintCount(address minter) external view returns (uint32 userMinted) {
        return uint32(_numberMinted(minter));
       
    }

    function reserveNFT(address to, uint16 amount) public onlyOwner {
        require(reservedNFTsAmount + amount <= reservedNFTs, "Oriental Dragonz: Out of stock");

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

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function isStarted(bool status) external onlyOwner {
        saleOn = status;
    }
}