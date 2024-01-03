// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20PresetMinterPauser.sol";

contract Axioms is ERC20PresetMinterPauser {
  constructor(uint256 _initialSupply) public ERC20PresetMinterPauser("Axioms", "AXI") {
    _mint(msg.sender, _initialSupply);
  }
}
