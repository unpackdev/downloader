// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./ERC20.sol";

contract ERC20Mock is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply
  ) ERC20(name, symbol) {
    if (initialSupply > 0) _mint(_msgSender(), initialSupply);
  }

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external {
    _burn(account, amount);
  }
}
