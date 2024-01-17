// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./PaymentSplitter.sol";

contract MetadropPaymentSplitter is PaymentSplitter {
  constructor(address[] memory payees, uint256[] memory shares_)
    PaymentSplitter(payees, shares_)
  {}
}
