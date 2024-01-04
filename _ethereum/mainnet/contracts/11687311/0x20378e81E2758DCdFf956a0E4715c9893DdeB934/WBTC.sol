// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Preset.sol";

contract WBTC is ERC20Preset {
  constructor(uint256 _initialSupply) public ERC20Preset("Wrapped Bitcoin", "WBTC", 8) {
    _mint(msg.sender, _initialSupply);
  }
}
