// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ShifterPoolQuery.sol";

contract GenesisQuery is ShifterPoolQuery {
  function execute(bytes memory /* context */) view public returns (uint256) {
    return isolate.genesis;
  }
}
