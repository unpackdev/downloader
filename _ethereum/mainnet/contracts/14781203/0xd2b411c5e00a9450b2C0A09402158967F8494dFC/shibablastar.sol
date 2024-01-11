// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";

contract ShibaBlastar is ERC20 {

  constructor() ERC20("SHIBA BLASTAR", "SABR") {
    _mint(msg.sender, 500000000000 * 10 ** uint256(decimals()));
  }
}