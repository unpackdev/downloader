//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract PogDAOToken is ERC20 {
  constructor(uint256 initialSupply) ERC20("PogDAOToken", "PAO") {
    _mint(msg.sender, initialSupply);
  }
}
