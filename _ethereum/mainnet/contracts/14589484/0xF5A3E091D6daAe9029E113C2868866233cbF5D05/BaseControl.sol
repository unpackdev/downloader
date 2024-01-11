// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Ownable.sol";

contract BaseControl is Ownable {
  // constants
  uint16 public constant MAX_SUPPLY = 10020;
  uint16 public constant MAX_SALE_SUPPLY = 10000;

  // variables
  bool public saleActive;
  uint16 public maxSaleAmount;

  uint256 public price;
  string public baseURI;
  string public unrevealedURI;

  // verified
  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  // verified
  function setMaxSaleAmount(uint16 _amount) external onlyOwner {
    require(_amount <= MAX_SALE_SUPPLY, "Exceed max");
    maxSaleAmount = _amount;
  }

  // verified
  function openPhase(uint16 _amount, uint256 _price) external onlyOwner {
    require(maxSaleAmount + _amount <= MAX_SALE_SUPPLY, "Exceed max");
    maxSaleAmount += _amount;
    price = _price;
  }

  // verified
  function toggleSale(bool _status) external onlyOwner {
    saleActive = _status;
  }

  // verified
  function setBaseURI(string memory _uri) external onlyOwner {
    baseURI = _uri;
  }

  function setRevealURI(string memory _uri) external onlyOwner {
    unrevealedURI = _uri;
  }
}
