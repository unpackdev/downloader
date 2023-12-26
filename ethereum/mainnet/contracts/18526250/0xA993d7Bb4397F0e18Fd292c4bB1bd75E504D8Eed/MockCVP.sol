// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract MockCVP is ERC20 {
  constructor() ERC20("Test CVP", "tCVP") {
    _mint(msg.sender, 2_000_000_000_000 * 10 ** decimals());
  }
}
