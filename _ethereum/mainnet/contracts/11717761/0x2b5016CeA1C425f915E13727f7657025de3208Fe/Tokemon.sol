// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Tokemon is ERC20, Ownable{

  string public constant tokenName = "Tokemon";
  string public constant tokenSymbol = "TKMN";
  uint public constant numberDecimals = 18;
  uint public constant initialSupply = 5000;

  constructor() public ERC20(tokenName, tokenSymbol) {
    _mint(msg.sender, initialSupply * 10 ** 18);
  }

}
