// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract xFellaz is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    uint256 public PRICE;
    string private BASE_URI;

    bool public IS_PRE_SALE_ACTIVE;
    bool public IS_PUBLIC_SALE_ACTIVE;
    
    uint256 public MAX_FREE_MINT_PER_WALLET;
    uint256 public MAX_MINT_PER_TRANSACTION;
    
    uint256 public MAX_FREE_MINT_SUPPLY; 
    uint256 public MAX_SUPPLY;

    mapping(address => uint256) private freeMintCounts;

    constructor(uint256 price, string memory baseURI, uint256 maxFreeMintPerWallet, uint256 maxMintPerTransaction, uint256 maxFreeMintSupply, uint256 maxSupply) ERC721A("0xFellaz", "0xFellaz") {
        PRICE = price;
        BASE_URI = baseURI;

        IS_PRE_SALE_ACTIVE = false;
        IS_PUBLIC_SALE_ACTIVE = false;

        MAX_FREE_MINT_PER_WALLET = maxFreeMintPerWallet;
        MAX_MINT_PER_TRANSACTION = maxMintPerTransaction;

        MAX_FREE_MINT_SUPPLY = maxFreeMintSupply;
        MAX_SUPPLY = maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setPrice(uint256 customPrice) external onlyOwner {
        PRICE = customPrice;
    }

    function lowerMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply < MAX_SUPPLY, "New max supply must be lower than current");
        require(newMaxSupply >= _currentIndex, "New max supply lower than total number of mints");
        MAX_SUPPLY = newMaxSupply;
    }

    function raiseMaxFreeMintSupply(uint256 newMaxFreeMintSupply) external onlyOwner {
        require(newMaxFreeMintSupply <= MAX_SUPPLY, "New max free mint supply must be lower or equal to max supply");
        require(newMaxFreeMintSupply > MAX_FREE_MINT_SUPPLY, "New max free mint supply must be higher than current");
        MAX_FREE_MINT_SUPPLY = newMaxFreeMintSupply;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        BASE_URI = newBaseURI;
    }

    function setPreSaleActive(bool preSaleIsActive) external onlyOwner {
        IS_PRE_SALE_ACTIVE = preSaleIsActive;
    }

    function setPublicSaleActive(bool publicSaleIsActive) external onlyOwner {
        IS_PUBLIC_SALE_ACTIVE = publicSaleIsActive;
    }

    modifier validMintAmount(uint256 _mintAmount) {
        require(_mintAmount > 0, "Must mint at least one token");
        require(_currentIndex + _mintAmount <= MAX_SUPPLY, "Exceeded max tokens minted");
        _;
    }

    function freeMint(uint256 _mintAmount) public payable validMintAmount(_mintAmount) {
        require(IS_PRE_SALE_ACTIVE, "Pre-sale is not active");
        require(freeMintCounts[msg.sender] + _mintAmount <= MAX_FREE_MINT_PER_WALLET, "Max amount of free mints per wallet exceeded");
        require(totalSupply() + _mintAmount <= MAX_FREE_MINT_SUPPLY, "Max free mint supply exceeded");
        
        // Update how many free mints this address has done
        freeMintCounts[msg.sender] += _mintAmount;

        _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable validMintAmount(_mintAmount) {
        require(IS_PUBLIC_SALE_ACTIVE, "Public sale is not active");
        require(_mintAmount <= MAX_MINT_PER_TRANSACTION, "Max amount of mints per transaction exceeded");
        require(msg.value >= SafeMath.mul(PRICE, _mintAmount), "Insufficient funds");
        
        _safeMint(msg.sender, _mintAmount);
    }

    function mintOwner(address _to, uint256 _mintAmount) public onlyOwner validMintAmount(_mintAmount) {
        _safeMint(_to, _mintAmount);
    }

    address private constant payoutAddress1 =
    0x573fbe11F7d06284b699dFd4B9C941D47700e6BA;

    address private constant payoutAddress2 =
    0x5Cb90548FaAeD7Aa5DAd107D35DEb266B1E7ED66;

    address private constant payoutAddress3 =
    0x6eF8C5eaEC11Fc6fa5bbA4BB183DFd5A1405E8cf;

    address private constant payoutAddress4 =
    0xea0F9254950C9dC5c2DD3423091ace518bd69aa9;

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(payoutAddress1), balance / 4);
        Address.sendValue(payable(payoutAddress2), balance / 4);
        Address.sendValue(payable(payoutAddress3), balance / 4);
        Address.sendValue(payable(payoutAddress4), balance / 4);
    }

}
