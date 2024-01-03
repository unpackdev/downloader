// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Preset.sol";

contract YGY is ERC20Preset {
  constructor(uint256 _initialSupply) public ERC20Preset("YGY", "YGY", 6) {
    _mint(msg.sender, _initialSupply);
  }
}
