// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SlimeSaga is ERC721Enumerable, Ownable {


    string _baseTokenURI;
    uint256 public maxSlimes;
    uint256 private slimePrice = 0.03 ether;
    bool public saleIsActive = false;

    constructor() ERC721("SlimeSaga", "SlimeTeam")  {
        maxSlimes = 3000;
    }


    function mintSlime(uint256 slimeQuantity) public payable {
        uint256 supply = totalSupply();
        require( saleIsActive,"Sale is paused" );
        require( slimeQuantity < 21,"Only 20 at a time" );
        require( supply + slimeQuantity <= maxSlimes, "Exceeds maximum supply" );
        require( msg.value >= slimePrice * slimeQuantity,"TX Value not correct" );

        for(uint256 i; i < slimeQuantity; i++){
            _safeMint( msg.sender, supply + i );
        }
    }


    function setPrice(uint256 newSlimePrice) public onlyOwner() {
        slimePrice = newSlimePrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function reserveSlimes() public onlyOwner {
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