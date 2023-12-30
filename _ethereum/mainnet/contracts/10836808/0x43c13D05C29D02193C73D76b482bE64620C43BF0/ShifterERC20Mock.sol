// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./TestToken.sol";

contract ShifterERC20Mock is TestToken {
  constructor() TestToken("zBTC", "zBTC", 8) public {}
  function fromUnderlying(uint256 amount) public pure returns (uint256) {
    return amount;
  }
}
