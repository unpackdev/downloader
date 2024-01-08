// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract Color is ERC721Enumerable, Ownable  {
    uint16 public constant MAX_TOKENS = 16 * 16 * 16;
    
    string private base = "https://colornft.me/";
    
    function _baseURI() internal view virtual override returns (string memory) {
        return base;
    }
    
    function setBaseURI(string memory _base) public onlyOwner {
        base = _base;
    }
  
    constructor() ERC721("Color", "Color") {}
    
    function mint(bool single)
        public
        payable
    {
        uint256 totalSupply = totalSupply();
        uint8 _count;
        uint256 _price;
        if(single) {
            _count = 1;
            _price = 29e15; // 0.029 Ether
        } else {
            _count = 16;
            _price = 464e14; // 0.464 Ether
        }
        require(totalSupply + _count < MAX_TOKENS + 1, "Token supply is not enough.");
        require(msg.value >= _price, "Ether value sent is not enough");
        
        for(uint8 i = 0; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function withdraw() public onlyOwner payable{
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);    
    }
}
