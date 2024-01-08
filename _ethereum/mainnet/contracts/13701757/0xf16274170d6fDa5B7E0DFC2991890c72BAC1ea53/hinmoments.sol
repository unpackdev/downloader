// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract HistoryInMoments is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    
    uint public price = 0.02 ether;
    uint public constant MAX_SUPPLY = 4400;
    uint public maxFreeMintPerWallet = 40;
    uint public maxFreeMint = 400;
    bool public isSalesActive = false;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("HistoryInMoments", "HM") {
        _contractUri = "ipfs://QmYKYsLS7ovK8FRtZANYXgB3J3QNaBD1xa4LWQySbuavEZ";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint() external {
        require(isSalesActive, "Sales is not actived yet");
        require(totalSupply() < maxFreeMint, "Sorry, no more free remaining");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "Wallet already minted for free");
        
        addressToFreeMinted[msg.sender]++;
        safeMint(msg.sender);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive, "Sales is not Activate yet");
        require(quantity <= 40, "Max Mint per transaction Exceeds");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Sorry, Sold out.");
        require(msg.value >= price * quantity, "ethereum sent is under price");
        
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