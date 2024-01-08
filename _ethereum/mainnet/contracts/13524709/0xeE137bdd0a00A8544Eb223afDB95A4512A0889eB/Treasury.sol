// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "./PaymentSplitter.sol";

contract Treasury is PaymentSplitter {
  uint256 private _numberOfPayees;

  constructor(address[] memory payees, uint256[] memory shares_) payable PaymentSplitter(payees, shares_) {
    _numberOfPayees = payees.length;
  }

  receive() external payable override {
    emit PaymentReceived(_msgSender(), msg.value);

    for (uint i = 0; i < _numberOfPayees; i++) {
      release(payable(payee(i)));
    }
  }
}