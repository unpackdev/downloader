// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./ERC20.sol";
import "./Ownable2Step.sol";

contract TSipher is ERC20, Ownable2Step {
  string private constant NAME = 'TSipher';
  string private constant SYMBOL = 'TSPR';
  uint256 private constant INITIAL_SUPPLY = 10_000_000_000 ether;

  constructor() ERC20(NAME, SYMBOL) {
    _mint(owner(), INITIAL_SUPPLY);
  }
}
