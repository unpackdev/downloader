// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract UnscratchedNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant GIFT_MINT_AMOUNT = 100;
    uint256 public constant WHITELIST_MINT_AMOUNT = 1500;
    uint256 public constant PUBLIC_MINT_AMOUNT = 3400;
    uint256 public constant MAX_MINT_AMOUNT = GIFT_MINT_AMOUNT + WHITELIST_MINT_AMOUNT + PUBLIC_MINT_AMOUNT;
    uint256 public constant PUBLIC_MINT_PRICE = 0.3 ether;
    uint256 public constant WHITELIST_MINT_PRICE = 0.25 ether;
    uint256 public constant PUBLIC_MAX_MINT_LIMIT = 5;
    uint256 public constant WHITELIST_MAX_MINT_LIMIT = 3;
    
    mapping(address => uint256) public whitelistPurchases;
    mapping(string => bool) private _usedNonces;
    
    string private _contractURI;
    string private _tokenBaseURI = "https://api.unscratchednft.com/metadata/";
    address private _signerAddress = 0x4AF3A88Eb19C4a240256dfFf1511FCc0C6194838;

    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    uint256 public whitelistAmountMinted;
    bool public saleLive;
    bool public locked;
    
    constructor() ERC721("Unscratched NFT", "UNSCRATCHED") { }
    
    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }
    
    function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, nonce)))
          );
          
          return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }
    
    function buy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
        require(saleLive, "PUBLIC_SALE_CLOSED");
        require(matchAddresSigner(hash, signature), "DIRECT_MINT_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
        require(totalSupply() < MAX_MINT_AMOUNT, "OUT_OF_STOCK");
        require(publicAmountMinted + tokenQuantity <= PUBLIC_MINT_AMOUNT, "EXCEED_PUBLIC");
        require(tokenQuantity <= PUBLIC_MAX_MINT_LIMIT, "EXCEED_PER_MINT_LIMIT");
        require(PUBLIC_MINT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        for(uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
        _usedNonces[nonce] = true;
    }
    
    function whitelistBuy(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
        require(saleLive, "WHITELIST_SALE_CLOSED");
        require(matchAddresSigner(hash, signature), "DIRECT_MINT_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
        require(totalSupply() < MAX_MINT_AMOUNT, "OUT_OF_STOCK");
        require(whitelistAmountMinted + tokenQuantity <= WHITELIST_MINT_AMOUNT, "EXCEED_WHITELIST");
        require(tokenQuantity <= WHITELIST_MAX_MINT_LIMIT, "EXCEED_PER_MINT_LIMIT");
        require(whitelistPurchases[msg.sender] + tokenQuantity <= WHITELIST_MAX_MINT_LIMIT, "EXCEED_ALLOC");
        require(WHITELIST_MINT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        for (uint256 i = 0; i < tokenQuantity; i++) {
            whitelistAmountMinted++;
            whitelistPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
         _usedNonces[nonce] = true;
    }
    
    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= MAX_MINT_AMOUNT, "MAX_MINT");
        require(giftedAmount + receivers.length <= GIFT_MINT_AMOUNT, "GIFTS_EMPTY");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function lockMetadata() external onlyOwner {
        locked = true;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
    
    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }
    
    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}