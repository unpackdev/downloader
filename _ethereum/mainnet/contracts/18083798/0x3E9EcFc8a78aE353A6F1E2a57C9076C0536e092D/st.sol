// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract STProtocol is ERC20 {
  constructor() ERC20("ST Protocol", "ST") {
    _mint(msg.sender, 10000000000 * 10 ** decimals());
  }
}