// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Burnable.sol";
import "./ERC20.sol";

contract TestToken is ERC20, ERC20Burnable {
  constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) public {
    _setupDecimals(decimals);
  }
  function mint(address user, uint256 amount) public {
    _mint(user, amount);
  }
}
