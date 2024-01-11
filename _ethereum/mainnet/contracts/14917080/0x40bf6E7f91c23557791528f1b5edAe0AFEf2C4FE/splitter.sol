// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract splitter is PaymentSplitter {

  constructor(
    address[] memory payees, 
    uint256[] memory shares
  ) PaymentSplitter(payees, shares) {}
  
}