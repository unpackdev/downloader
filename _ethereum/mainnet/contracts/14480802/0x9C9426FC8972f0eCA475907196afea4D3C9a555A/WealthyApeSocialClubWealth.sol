// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract WealthyApeSocialClubWealth is ERC20, ERC20Burnable {
  constructor() ERC20("Wealth", "$WEALTH") {
    _mint(msg.sender, 3570000000 * 10**decimals());
  }
}
