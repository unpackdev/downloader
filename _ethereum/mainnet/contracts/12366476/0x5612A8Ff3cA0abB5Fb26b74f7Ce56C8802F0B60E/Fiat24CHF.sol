// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Fiat24Token.sol";

contract Fiat24CHF is Fiat24Token {

  function initialize(address fiat24AccountProxyAddress, uint256 walkinLimit, uint256 withdrawCharge) initializer public {
      __Fiat24Token_init_(fiat24AccountProxyAddress, "Fiat24 CHF", "CHF24", walkinLimit, withdrawCharge);
  }
  
}
