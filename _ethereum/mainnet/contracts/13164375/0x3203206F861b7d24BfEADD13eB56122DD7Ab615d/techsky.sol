pragma solidity ^0.8.3;

// SPDX-License-Identifier: MIT
// Symbol        : TSY
// Name          : Tech Sky
// (c) by Tech Sky 2021. MIT Licence.
 
import "./ERC20.sol";

contract TechSky is ERC20 {
  constructor() ERC20('Tech Sky', 'TSY') {
    _mint(msg.sender, 120000000 * 10 ** 18);
  }
}