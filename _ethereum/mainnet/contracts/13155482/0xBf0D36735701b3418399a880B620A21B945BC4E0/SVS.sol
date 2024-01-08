// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
     ▄█▀▀▀█▄█   ▀████▀   ▀███▀    ▄█▀▀▀█▄█
    ▄██    ▀█     ▀██    ▄▄█     ▄██    ▀█
    ▀███▄          ██▄  ▄██      ▀███▄    
     ▀█████▄       ██▄  ▄█        ▀█████▄
    ▄     ▀██       ▀████▀       ▄     ▀██
    ██     ██        ▄██▄        ██     ██
    █▀█████▀          ██         █▀█████▀ 
    
      Sneaky Vampires Syndicate / 2021
*/
                                          
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SneakyVampireSyndicate is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    uint256 public constant SVS_GIFT = 88;
    uint256 public constant SVS_PRIVATE = 800;
    uint256 public constant SVS_PUBLIC = 8000;
    uint256 public constant SVS_MAX = SVS_GIFT + SVS_PRIVATE + SVS_PUBLIC;
    uint256 public constant SVS_PRICE = 0.08 ether;
    uint256 public constant SVS_PER_MINT = 10;
    
    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;
    
    string private _contractURI;
    string private _tokenBaseURI;
    string private _defaultBaseURI;
    address private _artistAddress = 0xea68212b0450A929B14726b90550933bC12fF813;
    
    string public proof;
    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    uint256 public privateAmountMinted;
    uint256 public presalePurchaseLimit = 2;
    bool public presaleLive;
    bool public saleLive;
    
    constructor() ERC721("Sneaky Vampire Syndicate", "SVS") { }
    
    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerList[entry], "DUPLICATE_ENTRY");

            presalerList[entry] = true;
        }   
    }

    function removeFromPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            
            presalerList[entry] = false;
        }
    }
    
    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "Sale is not live");
        require(!presaleLive, "Only presalers can buy");
        require(totalSupply() < SVS_MAX, "All Vampires are minted");
        require(publicAmountMinted + tokenQuantity <= SVS_PUBLIC, "Minting would exceed the max pubic supply");
        require(tokenQuantity <= SVS_PER_MINT, "You can mint up to 10 Vampires per transaction");
        require(SVS_PRICE * tokenQuantity <= msg.value, "Insufficient ETH sent");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function presaleBuy(uint256 tokenQuantity) external payable {
        require(!saleLive && presaleLive, "The presale is closed");
        require(presalerList[msg.sender], "You are not qualified for the presale");
        require(totalSupply() < SVS_MAX, "All Vampires are minted");
        require(privateAmountMinted + tokenQuantity <= SVS_PRIVATE, "Minting would exceed the presale allocation");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= presalePurchaseLimit, "You can mint up to 2 Vampires in the presale");
        require(SVS_PRICE * tokenQuantity <= msg.value, "Insufficient ETH sent");
        
        for (uint256 i = 0; i < tokenQuantity; i++) {
            privateAmountMinted++;
            presalerListPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= SVS_MAX, "MAX_MINT");
        require(giftedAmount + receivers.length <= SVS_GIFT, "GIFTS_EMPTY");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
    
    function withdraw() external onlyOwner {
        payable(_artistAddress).transfer(address(this).balance * 2 / 5);
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function isPresaler(address addr) external view returns (bool) {
        return presalerList[addr];
    }
    
    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    }

    function isSaleActive() external view returns(bool) {
        return saleLive;
    }
    
    function isPresaleActive() external view returns(bool) {
        return presaleLive;
    }
    // Owner functions for enabling presale, sale, revealing and setting the provenance hash
    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
    
    function setProvenanceHash(string calldata hash) external onlyOwner {
        proof = hash;
    }
    
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }
    
    function setDefaultBaseURI(string calldata URI) external onlyOwner {
        _defaultBaseURI = URI;
    }
    
    // aWYgeW91IHJlYWQgdGhpcywgc2VuZCBGcmVkZXJpayMwMDAxLCAiZnJlZGR5IGlzIGJpZyI=
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return bytes(_tokenBaseURI).length > 0 ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString())) : _defaultBaseURI;
    }
}