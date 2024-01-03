// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20.sol";

contract MockERC20 is ERC20 {
  constructor(string memory name, string memory symbol, uint256 amount_) public ERC20(name, symbol) {
    _mint(msg.sender, amount_);
  }
}
