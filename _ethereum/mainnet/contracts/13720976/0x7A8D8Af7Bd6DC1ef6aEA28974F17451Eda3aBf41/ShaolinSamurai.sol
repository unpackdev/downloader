// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Burnable.sol";

contract ShaolinSamurai is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    uint _splitterId;
    
    uint public constant MAX_SUPPLY = 8888;
    uint public price = 0.0888 ether;
    uint public maxFreeMint = 5;
    uint public maxFreeMintPerWallet = 5;
    bool public isSalesActive = false;

    address constant _devAddress = 0x47017144be3f7E6768366D6afB62c6334B7AB41A;
    address constant _ownerAddress = 0xcE45ee964a34aCB520Ac15eeb70d49911D5ccbb7;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("Shaolin Samurai", "SHAOSAMURAI") { 
        _contractUri = "ipfs://Qmd9rquCQS9Aup52a9acUwjmRg5DjRH8PxC3f5hvNKEnw5";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint() external {
        require(isSalesActive, "sale is not active");
        require(totalSupply() < maxFreeMint, "theres no free mints remaining");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "caller already minted for free");
        
        addressToFreeMinted[msg.sender]++;
        safeMint(msg.sender);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive, "sale is not active");
        require(quantity <= 10, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= MAX_SUPPLY, "sold out");
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
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }    
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
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

    function withdrawAll() public onlyOwner {
        require(payable(_devAddress).send(address(this).balance * 20 / 100));
        require(payable(_ownerAddress).send(address(this).balance));
    }
}