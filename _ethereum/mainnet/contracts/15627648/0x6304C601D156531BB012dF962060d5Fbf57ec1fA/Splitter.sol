// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./PaymentSplitter.sol";

// @author rollauver.eth

contract Splitter is Ownable, PaymentSplitter {
  constructor(
    address[] memory payees,
    uint256[] memory shares
  ) PaymentSplitter(payees, shares) {}
}
