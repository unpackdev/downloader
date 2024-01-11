// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PaymentSplitter.sol";

contract Splitter is PaymentSplitter {
  constructor(address[] memory payees, uint256[] memory shares_) payable PaymentSplitter(payees, shares_) {}
}
