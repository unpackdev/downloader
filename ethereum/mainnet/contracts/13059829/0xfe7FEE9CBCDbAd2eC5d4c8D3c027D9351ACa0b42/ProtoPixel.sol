// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract ProtoPixels is ERC721Enumerable, Ownable {


    string _baseTokenURI;
    uint256 public maxPixels;
    uint256 private pixelPrice = 0.02 ether;
    bool public saleIsActive = false;

    constructor() ERC721("ProtoPixels", "CTRLPLUS")  {
        maxPixels = 6200;
        setBaseURI("ipfs://QmYexZURH5SGj38x9Cwt9HVNjFoNGb49EJWUw2Niuic1y2/");
    }


    function mintPixel(uint256 pixelQuantity) public payable {
        uint256 supply = totalSupply();
        require( saleIsActive,"Sale is paused" );
        require( pixelQuantity < 21,"Only 20 at a time" );
        require( supply + pixelQuantity <= maxPixels, "Exceeds maximum supply" );
        require( msg.value >= pixelPrice * pixelQuantity,"TX Value not correct" );

        for(uint256 i; i < pixelQuantity; i++){
            _safeMint( msg.sender, supply + i );
        }
    }


    function setPrice(uint256 newPixelPrice) public onlyOwner() {
        pixelPrice = newPixelPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function reservePixels() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 40; i++) {
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