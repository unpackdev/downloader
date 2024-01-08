// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";

contract Token is IERC20, ERC20, Ownable {
  
  constructor() ERC20("Block52", "B52") {
    _mint(0x9572E2a1DF6CE89a632dA4d29d6b48453F505e85, 52000000000000000000000000);
  }
}