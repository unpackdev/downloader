// SPDX-License-Identifier: MIT
// Mock ERC20 token for testing

pragma solidity 0.7.6;

import "./ERC20.sol";

contract MockERC20 is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) ERC20(name, symbol) {
    _setupDecimals(decimals);
  }

  function mint(address to, uint amount) external {
    _mint(to, amount);
  }
}
