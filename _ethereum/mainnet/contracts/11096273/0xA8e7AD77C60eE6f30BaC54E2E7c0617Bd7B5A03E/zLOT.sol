// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./ERC20.sol";

contract zLOT is ERC20 {
  constructor() public ERC20("zLOT", "zLOT") {
    _mint(msg.sender, 8888 ether);
  }
}
