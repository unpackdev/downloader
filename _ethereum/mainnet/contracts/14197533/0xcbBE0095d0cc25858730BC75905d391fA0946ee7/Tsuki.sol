// SPDX-License-Identifier: MIT
//Take
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract TalesOfTsuki is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    
    bool public isSalesActive = true;
    uint public constant MAX_SUPPLY = 9999;

    uint public price = 0.1 ether;

    uint public maxFreeMintPerWallet = 30;
    
    uint public maxFreeMint = 30;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("Tales of Tsuki", "TSUKI") {
        _contractUri = "ipfs://QmfMEGRGnCSXi26SGYt8ixkMQwgkcWoTK1CUsqddgHsNuB";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint() external {
        require(isSalesActive, "Tsuki sales is not active yet");
        require(totalSupply() < maxFreeMint, "theres no Tsuki free mints remaining");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "caller already minted for free");
        
        addressToFreeMinted[msg.sender]++;
        safeMint(msg.sender);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive, "Tsuki sale is not active");
        require(quantity <= 20, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Tsuki is sold out");
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