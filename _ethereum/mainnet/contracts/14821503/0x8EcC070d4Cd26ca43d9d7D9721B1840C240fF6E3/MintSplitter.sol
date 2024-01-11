// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Splitter.sol";

contract MintSplitter is Splitter {
  constructor(address[] memory payees, uint256[] memory shares) Splitter(payees, shares) {}
}