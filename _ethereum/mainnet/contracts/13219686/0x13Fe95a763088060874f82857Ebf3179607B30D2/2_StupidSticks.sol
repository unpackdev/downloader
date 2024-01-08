// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Shqkn is ERC721Enumerable, Ownable {

    
    string _baseTokenURI;
    uint256 public maxSticks;
    uint256 private sticksPrice = 0.01 ether;
    bool public saleIsActive = false;

    constructor() ERC721("Stupid Sticks", "Shqkn")  {
        maxSticks = 2500;
    }
   

   function mintSticks(uint256 SticksQuantity) public payable {
        uint256 supply = totalSupply();
        require( saleIsActive,"Sale is paused" );
        require( SticksQuantity < 21,"Only 20 at a time" );
        require( supply + SticksQuantity <= maxSticks, "Exceeds maximum supply" );
        require( msg.value >= sticksPrice * SticksQuantity,"TX Value not correct" );

        for(uint256 i; i < SticksQuantity; i++){
            _safeMint( msg.sender, supply + i );
        }
    }


    function setPrice(uint256 newStickPrice) public onlyOwner() {
        sticksPrice = newStickPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function reserveSticks() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 20; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

 function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }
}