// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MinteVipTicket
/// @authors: manifold.xyz & Collector

import "./ERC721Creator.sol";


contract MVIP is ERC721Creator {
     uint256 public price = 40000000000000000; //0.04 ETH
     bool public saleIsActive = true;
     uint private rand;

    constructor(string memory tokenName, string memory symbol) ERC721Creator(tokenName, symbol) {}

    /* claim multiple tokens */
    function claimBatch(address to, uint256 _qty) public nonReentrant payable {
      require(_qty > 0, "Quantity must be more than 0");
      require(saleIsActive, "Sale must be active to mint");
      require(msg.value >= price*_qty, "Price is not correct.");
      string memory uri;
      for (uint i = 0; i < _qty; i++) {
          require(_tokenCount < MAX_TICKETS, "Maximum amount of tickets already minted." );
          rand = (pseudo_rand()%100)+1;
          uri = getVIPUri(rand);
          _mintBase(to, uri);
      }
    }

    function getVIPUri(uint r) private pure returns (string memory) {
      string memory uri;
      if (r < 41 ){
        uri = "ipfs://QmTfFj2d8oXRRhmFG9h82zkSdTjzEiqk3ZCiotFp2XLtfg"; //DYNASTY
      } else if (r >= 41 && r <  69){
        uri = "ipfs://QmYXwKTQRutEgMyjP35kcSqvZ6mZnB92Q4Hgu7LnVvLD4j"; //RELICS
      } else if (r >= 69 && r < 86){
        uri = "ipfs://QmW7us4Zmk9ZcZQVgR17QijKCXFMFCXvtLxwSL9gFFFL6y"; //ROYALS
      } else if (r >= 86 && r < 96){
        uri = "ipfs://QmR2LJjd7hCm95FFtVvgxz8f98LKLTQeXgHdWqHiwnToQR"; //LEGENDS
      } else if (r >= 96 && r < 100){
        uri = "ipfs://QmYtD7m8mUb3JHwQCEaskjW9KPwrr2XgQNnFEwjLnnEzkC"; //COSMOS
      } else {
        uri = "ipfs://QmQDAGCT5ux1Fc6zTKjbVNF18KofYpLDTK7AiRN3P5dP4C"; //GENESIS
      }
      return uri;
    }

    function pseudo_rand() private view returns (uint) {
      return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _tokenCount)));
    }

    function withdraw() public payable adminRequired {
       require(payable(_msgSender()).send(address(this).balance));
    }

    function changeSaleState() public adminRequired {
      saleIsActive = !saleIsActive;
    }

    function changePrice(uint256 newPrice) public adminRequired {
      price = newPrice;
    }
}
