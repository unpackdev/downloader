// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract SexyTokens is ERC721A, Ownable {
  bool public isPublicSaleActive;

  constructor() ERC721A("SexyTokens", "SEXY") {
      isPublicSaleActive = false;
  }

  function mint(uint256 _mintAmount) public {
    require(isPublicSaleActive, "Sale not set yet you idiot");
    _safeMint(msg.sender, _mintAmount);
  }
  function setPublicsale() public onlyOwner {
    isPublicSaleActive = !isPublicSaleActive;
  }
}