// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20PresetMinterPauser.sol";

contract NAP is ERC20PresetMinterPauser {
  constructor(uint256 _initialSupply) public ERC20PresetMinterPauser("ZZZ", "ZZZV1") {
    _mint(msg.sender, _initialSupply);
  }
}
