// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC777.sol";

contract Token is ERC777 {
  address[] private NO_DEFAULT_OPERATORS;

  constructor(string memory name, string memory symbol, uint256 totalSupply) ERC777(name, symbol, NO_DEFAULT_OPERATORS) {
    _mint(msg.sender, totalSupply * 10**18, "", "");
  }
}