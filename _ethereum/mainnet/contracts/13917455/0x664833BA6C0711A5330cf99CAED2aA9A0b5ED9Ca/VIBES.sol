// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.0;

contract GoodVibes is ERC20 {
  constructor() ERC20("Good Vibes", "VIBES") {
    _mint(msg.sender, 100000000 * 10 ** decimals());
  }
}
