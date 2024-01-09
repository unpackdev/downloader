//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "./draft-ERC20Permit.sol";
import "./ERC20Burnable.sol";
import "./ERC20.sol";


contract SNWGEM is ERC20, ERC20Permit, ERC20Burnable {
  constructor() ERC20("SNW GEM", "GEM") ERC20Permit("SNW GEM") {
    _mint(msg.sender, 100000000 * (10 ** 18));
  }
}