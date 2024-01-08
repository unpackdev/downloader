// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

contract Token is ERC20Permit {

  constructor(address safe) ERC20("Decenterlab", "DLAB") ERC20Permit("Decenterlab") {
    _mint(safe, 1_000_000 * (10 ** decimals()));
  }

  function decimals() public view virtual override returns (uint8) {
    return 18;
  }
}
