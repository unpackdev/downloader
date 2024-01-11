// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PaymentSplitter.sol";

contract Love15Payments is PaymentSplitter {
  constructor(address[] memory _payees, uint256[] memory _shares) payable PaymentSplitter(_payees, _shares) {}
}
