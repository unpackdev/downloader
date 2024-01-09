//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./PaymentSplitter.sol";

// @author numbco.art
// @title Minting Miracles Royalty Payment Splitter
contract RoyaltyPaymentSplitter is PaymentSplitter {
  address[] private royaltyPayeeAddresses;

  constructor(
    address[] memory _royaltyPayeeAddresses,
    uint256[] memory royaltyPayeeShares
  ) PaymentSplitter(_royaltyPayeeAddresses, royaltyPayeeShares) {
    royaltyPayeeAddresses = _royaltyPayeeAddresses;
  }
}
