// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC20Permit.sol";

contract TestERC20 is ERC20("USDC", "USDC"), ERC20Permit("USDC") {
  constructor(uint256 initialSupply, uint8 decimals) public {
    _setupDecimals(decimals);
    _mint(msg.sender, initialSupply);
  }
}
