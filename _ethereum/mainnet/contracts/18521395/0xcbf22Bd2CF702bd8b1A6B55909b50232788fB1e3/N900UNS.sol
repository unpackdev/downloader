// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

interface INounsToken {
   function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract N900UNS is ERC721Enumerable, Ownable {
   uint256 public mintFee = 0.005 ether;
   uint256 public MAX_SUPPLY = 900;
   INounsToken private nounsToken;
   address private NOUNS_DA0 = 0xb1a32FC9F9D8b2cf86C068Cae13108809547ef71;

   constructor(address initialOwner)
      ERC721("N900UNS", "N900UNS")
      Ownable(initialOwner) 
   {
      nounsToken = INounsToken(0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03);
      _safeMint(initialOwner, 0);
   }

   function tokenURI(uint256 tokenId) override public view returns (string memory){
      string  memory uri = nounsToken.tokenURI(tokenId);
      return uri;
   }

   function setMint(uint256 newFee) public onlyOwner {
      mintFee = newFee;
   }

   function mintNext() public payable {
      require(msg.value == mintFee, "Incorrect fee paid");
      uint256 tokenId = totalSupply();
      require(tokenId < MAX_SUPPLY, "Supply limit reached.");
      _safeMint(msg.sender, tokenId);
   }

   function withdraw() public onlyOwner {
      uint256 halfBalance = address(this).balance / 2;
      payable(owner()).transfer(halfBalance);
      payable(NOUNS_DA0).transfer(halfBalance);
   }
}
