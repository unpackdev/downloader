// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract SquirlGame is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    
    uint public constant MAX_SUPPLY = 3333;
    uint public maxFreeMint = 111;
    uint public price = 0.0231 ether;
    uint public maxFreeMintPerWallet = 20;
    bool public isSalesActive = false;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("SquirlGame", "SQUIRL") {
        _contractUri = "ipfs://QmUXBgGPRf6DBZFqgaSdJSGu2Xfjq5zebkj8t2TnHhEUhd";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint() external {
        require(isSalesActive, "SQUIRL sale is not active yet");
        require(totalSupply() < maxFreeMint, "There's no more SQUIRL free mint left");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "You already minted for free");
        
        addressToFreeMinted[msg.sender]++;
        safeMint(msg.sender);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive, "SQUIRL sale is not active yet");
        require(quantity <= 35, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Sold out");
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