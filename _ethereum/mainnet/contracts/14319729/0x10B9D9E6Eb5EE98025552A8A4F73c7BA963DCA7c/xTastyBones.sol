// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

contract xTastyBones is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    bytes32 public MERKLE_ROOT; 

    uint256 public PRICE;
    uint256 public WHITELIST_PRICE;
    string private BASE_URI;

    bool public IS_PRE_SALE_ACTIVE;
    bool public IS_PUBLIC_SALE_ACTIVE;
    
    uint256 public MAX_MINT_PER_WALLET;
    uint256 public MAX_MINT_PER_TRANSACTION;
    
    uint256 public MAX_SUPPLY;

    constructor(
        bytes32 merkleRoot, 
        uint256 price, 
        uint256 whitelistPrice, 
        string memory baseURI, 
        uint256 maxMintPerWallet, 
        uint256 maxMintPerTransaction, 
        uint256 maxSupply
        ) ERC721A("xTastyBones", "xTastyBones") {

        MERKLE_ROOT = merkleRoot;
        
        PRICE = price;
        WHITELIST_PRICE = whitelistPrice;
        
        BASE_URI = baseURI;

        IS_PRE_SALE_ACTIVE = false;
        IS_PUBLIC_SALE_ACTIVE = false;

        MAX_MINT_PER_WALLET = maxMintPerWallet;
        MAX_MINT_PER_TRANSACTION = maxMintPerTransaction;

        MAX_SUPPLY = maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        MERKLE_ROOT = newMerkleRoot;
    }

    function setPrice(uint256 customPrice) external onlyOwner {
        PRICE = customPrice;
    }
    
    function setWhitelistPrice(uint256 customPrice) external onlyOwner {
        WHITELIST_PRICE = customPrice;
    }

    function lowerMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply < MAX_SUPPLY, "New max supply must be lower than current");
        require(newMaxSupply >= _currentIndex, "New max supply lower than total number of mints");
        MAX_SUPPLY = newMaxSupply;
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
        require(_mintAmount <= MAX_MINT_PER_TRANSACTION, "Max amount of mints per transaction exceeded");
        require(balanceOf(msg.sender) + _mintAmount <= MAX_MINT_PER_WALLET, "Max amount of mints per wallet exceeded");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable validMintAmount(_mintAmount) {
        require(IS_PRE_SALE_ACTIVE, "Pre-sale is not active");
        require(msg.value >= SafeMath.mul(WHITELIST_PRICE, _mintAmount), "Insufficient funds");
        require(MerkleProof.verify(_merkleProof, MERKLE_ROOT, keccak256(abi.encodePacked(msg.sender))), 'Address is not whitelisted');

        _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable validMintAmount(_mintAmount) {
        require(IS_PUBLIC_SALE_ACTIVE, "Public sale is not active");
        require(msg.value >= SafeMath.mul(PRICE, _mintAmount), "Insufficient funds");
        
        _safeMint(msg.sender, _mintAmount);
    }

    function mintOwner(address _to, uint256 _mintAmount) public onlyOwner {
        require(_mintAmount > 0, "Must mint at least one token");
        require(_currentIndex + _mintAmount <= MAX_SUPPLY, "Exceeded max tokens minted");
        
        _safeMint(_to, _mintAmount);
    }

    address private constant payoutAddress1 =
    0xb34Ce2526a4a74Ac657cBF5eb947fEE80DA1de0F;

    address private constant payoutAddress2 =
    0x618E73405A82D82AE1A430b1083b857a93C3d7a8;

    address private constant payoutAddress3 =
    0x98b5eE0c0e6bce2E73c3b0E429396348f07519Ba;

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAddress1), SafeMath.div(SafeMath.mul(balance, 75), 100));
        Address.sendValue(payable(payoutAddress2), SafeMath.div(SafeMath.mul(balance, 15), 100));
        Address.sendValue(payable(payoutAddress3), SafeMath.div(SafeMath.mul(balance, 10), 100));
    }

}
