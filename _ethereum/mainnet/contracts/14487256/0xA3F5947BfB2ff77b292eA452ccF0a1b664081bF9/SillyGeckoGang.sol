// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721.sol";
 
contract SillyGeckoGang is ERC721, Ownable {
 
   uint public totalSupply = 0;
   uint public price = 0.05 ether;
   uint public maxSupply = 4444;
   uint public freeMintSupply = 1111;
   uint public maxItem = 10;
   string public _baseTokenURI;
   bool public saleState = false;
 
   address m1 = 0x070D6e6F94599CB66D649B3AFE1b60Ffe1187F40;
   address m2 = 0xE32850e8e4b7faF5d71d5142A4Ca74F7ad4e6AE3;

   constructor() ERC721("Silly Gecko Gang", "SGG") {
       transferOwnership(0x8ee13fe15d786e2933987fAf07AfeBeC813650dA);
   }
 
   function publicMint(uint amount) external payable {
       require(amount > 0, "Can't mint zero");
 
       require(msg.value == amount * price, "Send proper ETH amount");
 
       _rawMint(msg.sender, amount);
   }
 
   function _rawMint(address to, uint amount) internal {
       require(saleState, "Sale is not active in the moment");
       require(totalSupply + amount <= maxSupply, "Sold out");
       require(amount <= maxItem, "You can only mint 10 NFT at a time");
       for (uint i = 0; i < amount; i++) {
           _mint(to, totalSupply);
           totalSupply += 1;
       }
   }
 
   function freeMint(uint amount) external {
       require(amount > 0, "Can't mint zero");
       require(freeMintSupply > 0, "No more free mint");
 
       _rawMint(msg.sender, amount);
       freeMintSupply -= amount;
   }
 
   function ownerMint(uint amount) external onlyOwner {
       _rawMint(msg.sender, amount);
   }
 
   function withdraw() public payable onlyOwner {
       uint256 _each = address(this).balance / 2;
       require(payable(m1).send(_each));
       require(payable(m2).send(_each));
   }
 
   function flipSaleState() public onlyOwner {
       saleState = !saleState;
   }
 
   function setMintPrice(uint _price) external onlyOwner {
       price = _price;
   }
 
   function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
       _baseTokenURI = __baseTokenURI;
   }
 
   function tokenURI(uint256 _tokenId) public view override returns (string memory) {
       return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
   }
 
}

