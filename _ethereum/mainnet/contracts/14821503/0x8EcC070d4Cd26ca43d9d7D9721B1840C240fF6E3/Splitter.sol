// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract Splitter is PaymentSplitter, Ownable {
  address[] private _payees;

  constructor(address[] memory payees, uint256[] memory shares_) PaymentSplitter(payees, shares_) {
    _payees = payees;
  }

  function flush() public onlyOwner {
    for (uint256 i = 0; i < _payees.length; i++) {
      address addr = _payees[i];
      release(payable(addr));
    }
  }

  function flushToken(IERC20 token) public onlyOwner {
    for (uint256 i = 0; i < _payees.length; i++) {
      address addr = _payees[i];
      release(token, payable(addr));
    }
  }
}