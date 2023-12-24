// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";

contract ERC20Token is ERC20Burnable {
  constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
    _mint(msg.sender, initialSupply);
  }
}
