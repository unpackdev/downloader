// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ExtraTrippinApes is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    
    uint public price = 0.005 ether;
    uint public maxFreeMint = 4000;
    uint public constant MAX_SUPPLY = 10000;
    uint public maxFreeMintPerWallet = 9;
    bool public isSalesActive = true;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("Extra Trippin Apes", "ETA") {
        _contractUri = "ipfs://QmX3AcKFedjFQa5KXYrraPhvY1z34Z7yMcBn36yML35VSf";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint() external {
        require(isSalesActive, "sales is not active yet");
        require(totalSupply() < maxFreeMint, "No more free mints for you!");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "caller already minted for free");
        
        addressToFreeMinted[msg.sender]++;
        safeMint(msg.sender);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive, "sale is not active yet");
        require(quantity <= 30, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= MAX_SUPPLY, "sold out!");
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