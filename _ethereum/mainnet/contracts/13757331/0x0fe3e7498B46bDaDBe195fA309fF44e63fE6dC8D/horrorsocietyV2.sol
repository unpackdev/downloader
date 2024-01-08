// SPDX-License-Identifier: MIT
//  _                                                _      _         
// | |                                              (_)    | |        
// | |__   ___  _ __ _ __ ___  _ __   ___  ___   ___ _  ___| |_ _   _ 
// | '_ \ / _ \| '__| '__/ _ \| '__| / __|/ _ \ / __| |/ _ \ __| | | |
// | | | | (_) | |  | | | (_) | |    \__ \ (_) | (__| |  __/ |_| |_| |
// |_| |_|\___/|_|  |_|  \___/|_|    |___/\___/ \___|_|\___|\__|\__, |
//                                                               __/ |
//  by Hotcafe® 2021  https://hotcafe.io                         |___/ 

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract HorrorSocietyV2 is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    
    uint public maxFreeMintPerWallet = 30;
    uint public maxFreeMint = 500;
    uint public price = 0.021 ether;
    uint public constant MAX_SUPPLY = 5000;
    bool public isSalesActive = false;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("HorrorSocietyV2", "HSV2") {
        _contractUri = "ipfs://QmdvvVEJ2mdFFbjSAWGEYbX2FQKBMNAiStHM9v5GecwYBq";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint() external {
        require(isSalesActive, "Horror Society sale is not active yet");
        require(totalSupply() < maxFreeMint, "There's no more free mint left, bleh");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "Sorry, already minted for free");
        
        addressToFreeMinted[msg.sender]++;
        safeMint(msg.sender);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive, "Horror Society sale is not active yet");
        require(quantity <= 35, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= MAX_SUPPLY, "We Sold out!");
        require(msg.value >= price * quantity, "ether send is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }
    
    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}