// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20.sol";

contract TokenCoin is ERC20 {
  constructor(string memory name_, string memory symbol_, uint256 initialSupply_) public ERC20(name_, symbol_) {
    _mint(msg.sender, initialSupply_ * 10 ** uint256(18)); // total supply * 10^18
  }
}