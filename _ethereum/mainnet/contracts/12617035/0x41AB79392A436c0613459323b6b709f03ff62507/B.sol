// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.5;

import "./ERC20.sol";

contract B is ERC20 {
  constructor() ERC20("B", "B") {
    _mint(msg.sender, 1000 ether); // ether just means 18 decimals
  }
}
