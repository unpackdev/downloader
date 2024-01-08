// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20PresetFixedSupply.sol";

contract XBXToken is ERC20PresetFixedSupply {
  uint8 public constant DECIMALS = 18;
  uint256 public constant INITIAL_SUPPLY = 9999999999 * (10 ** uint256(DECIMALS));

  constructor(address _owner) ERC20PresetFixedSupply("XBX", "XBX", INITIAL_SUPPLY, _owner) {}
}
