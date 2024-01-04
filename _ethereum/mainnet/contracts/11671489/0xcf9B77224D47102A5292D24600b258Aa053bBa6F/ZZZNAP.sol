// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20PresetMinterPauser.sol";

contract ZZZNAP is ERC20PresetMinterPauser {
  constructor(uint256 _initialSupply) public ERC20PresetMinterPauser("ZZZNAP", "ZZZNAP") {
    _mint(msg.sender, _initialSupply);
  }
}
