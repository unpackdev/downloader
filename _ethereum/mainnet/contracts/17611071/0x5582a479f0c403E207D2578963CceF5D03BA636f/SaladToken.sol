// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";

contract SaladToken is Ownable, ERC20, ERC20Burnable, ERC20Pausable {
  string private constant NAME = "Salad";
  string private constant SYMBOL = "SALD";

  uint public constant TOTAL_SUPPLY = 1_680_000_000e18; // 1.68b SALD

  constructor() ERC20(NAME, SYMBOL) {
    _mint(owner(), TOTAL_SUPPLY);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}
