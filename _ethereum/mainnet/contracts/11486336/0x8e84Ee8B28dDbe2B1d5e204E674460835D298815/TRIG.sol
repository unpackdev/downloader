// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import "./ERC20.sol";

contract TRIG is ERC20 {
  uint256 public constant MAX_SUPPLY = 1000 ether;

  constructor(string memory name, string memory symbol)
    public
    ERC20(name, symbol)
  {
    _mint(msg.sender, MAX_SUPPLY);
  }
}
