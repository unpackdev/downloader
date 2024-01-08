// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract TheAura is ERC721, Ownable {
    string internal baseTokenURI;

    uint public price = 0.01 ether;
    uint public totalSupply = 10000;
    uint public total = 0;
    uint public max = 10;

    mapping (address => uint256) public store;

    constructor() ERC721("THE AURA", "AURA") {}
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }
    
    function setMax(uint qty) external onlyOwner {
        max = qty;
    }
    
    function getAssetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < total; i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
    
    function freeMint(address to, uint qty) external onlyOwner {
        require(qty + total <= totalSupply, "S O L D O U T");
        for(uint i = 0; i < qty; i++){
            uint tokenId = total;
            _safeMint(to, tokenId);
            total++;
        }
    }
    
    function mint(uint qty) external payable {
        uint256 holding = store[msg.sender];
        require(qty <= max || qty < 1, "H I G H E R T H A N M A X P E R T X");
        require(qty + total <= totalSupply, "S O L D O U T");
        require(msg.value == price * qty, "P R I C E");
        require(holding + qty <= 10, "G A M E O V E R");

        store[msg.sender] += qty;

        for(uint i = 0; i < qty; i++){
            uint tokenId = total;
            _safeMint(msg.sender, tokenId);
            total++;
        }
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
