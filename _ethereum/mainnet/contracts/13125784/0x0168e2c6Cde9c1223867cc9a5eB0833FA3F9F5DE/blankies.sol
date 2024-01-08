// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Blankies is ERC721, Ownable {
    using Counters for Counters.Counter;
    
    uint constant public maxSupply = 3333;
    uint public claimPrice = 0.015 ether;
    bool public mintEnabled = true;
    string private _internalBaseURI;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Blankies", "BLANK") {
    }

    function _baseURI() internal view override returns (string memory) {
        return _internalBaseURI;
    }

    function safeMint(address to) public onlyOwner {
        require(_tokenIdCounter.current() < maxSupply);
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function enableMint() public onlyOwner {
        mintEnabled = true;
    }

    function disableMint() public onlyOwner {
        mintEnabled = false;
    }

    function updateURI(string memory uri) public onlyOwner {
        _internalBaseURI = uri;
    }

    function mintMany(uint amount) public payable {
        require(mintEnabled == true);
        uint totalValue = amount * claimPrice;
        require(msg.value == totalValue);
        payable(owner()).transfer(msg.value);
        
        for (uint i=0; i<amount; i++) {
            require(_tokenIdCounter.current() < maxSupply);
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
    
    function getCurrent() external view returns(uint) {
        return _tokenIdCounter.current();
    }
}
