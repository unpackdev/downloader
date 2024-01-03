// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20.sol";

contract MockCVP is ERC20 {
  constructor(uint256 amount_) public ERC20("CVP", "CVP") {
    _mint(msg.sender, amount_);
  }
}
