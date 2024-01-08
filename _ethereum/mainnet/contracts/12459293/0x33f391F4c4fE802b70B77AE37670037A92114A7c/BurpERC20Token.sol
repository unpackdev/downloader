// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./ERC20PresetFixedSupply.sol";

contract BurpERC20Token is ERC20PresetFixedSupply {
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply,
    address owner
  ) public ERC20PresetFixedSupply(name, symbol, initialSupply, owner) { }

}