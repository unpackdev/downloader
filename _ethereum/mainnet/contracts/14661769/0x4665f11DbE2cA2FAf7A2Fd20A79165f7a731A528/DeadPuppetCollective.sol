//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ERC721A.sol";

contract DeadPuppetCollective is Ownable, ERC721A, ReentrancyGuard {
    uint256 public price = 10000000000000000; // 0.01 ETH;
    uint256 public supply = 4000;
    uint256 public constant maxPerTxPublicSale = 10;

    bool public publicSaleLive;
    
    constructor() ERC721A("Dead Puppet Collective", "TDPC"){}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is contrat");
        _;
    }

    function publicSaleMint(uint256 _amount) public payable callerIsUser {
        require(publicSaleLive, "Not live");
        require(_amount > 0, "Not enough");
        require(_amount <= maxPerTxPublicSale, "Too many");
        require(totalSupply() + _amount <= supply, "Exceeds supply");
        require(msg.value == _amount * price, "Wrong value");        
        _safeMint(msg.sender, _amount);
    }

    function flipPublicSale() external onlyOwner {
        publicSaleLive = !publicSaleLive;
    }

    // for marketing, team etc.
    function devMint(uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= supply, "Too many");
        _safeMint(msg.sender, _amount);
    }

    function adjustPrice(uint256 _newprice) external onlyOwner {
        price = _newprice;
    }

    function adjustSupply(uint256 _newsupply) external onlyOwner {
        supply = _newsupply;
    }

    // metadata URI
    string private baseUri = "https://mint.deadpuppetco.io/api/json/";

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string calldata _baseTokenUri) external onlyOwner {
        baseUri = _baseTokenUri;
    }

    function withdraw() external onlyOwner nonReentrant {
        payable(msg.sender).transfer((address(this).balance));
    }
}

