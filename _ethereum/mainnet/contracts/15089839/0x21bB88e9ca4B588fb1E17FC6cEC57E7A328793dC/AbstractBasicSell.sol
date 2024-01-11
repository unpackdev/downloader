// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";

abstract contract AbstractBasicSell is Ownable {
  uint256 public price;

  constructor(uint256 price_) {
    price = price_;
  }

  function setPrice(uint256 price_) external onlyOwner {
    price = price_;
  }
}
