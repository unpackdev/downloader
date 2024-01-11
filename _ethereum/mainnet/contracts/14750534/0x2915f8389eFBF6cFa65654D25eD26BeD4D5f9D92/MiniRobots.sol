// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract MiniRobots is Ownable, ERC721A, ReentrancyGuard {


    uint256 public maxSupply = 3333;
    uint256 public mintTX = 20;
    string public baseURI;
    uint256 public price = 0.001 ether;

    constructor() 
        ERC721A("Mini Robots", "BOT", 20, 3333)  {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    function mint(uint256 amount) payable public {
        require(totalSupply() + amount <= maxSupply, "Soldout");
        require(amount <= mintTX,"Maximum 20 Per TX");
        require(msg.value >= price * amount, "Insufficient ETH");
        _safeMint(msg.sender, amount);
    }
    
}