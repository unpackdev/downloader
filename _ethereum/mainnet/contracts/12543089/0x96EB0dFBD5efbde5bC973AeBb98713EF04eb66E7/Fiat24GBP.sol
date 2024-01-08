// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Fiat24Token.sol";

contract Fiat24GBP is Fiat24Token {

  function initialize(address fiat24AccountProxyAddress, uint256 walkinLimit, uint256 withdrawCharge) public initializer {
      __Fiat24Token_init_(fiat24AccountProxyAddress, "Fiat24 GBP", "GBP24", walkinLimit, withdrawCharge);
  }
}