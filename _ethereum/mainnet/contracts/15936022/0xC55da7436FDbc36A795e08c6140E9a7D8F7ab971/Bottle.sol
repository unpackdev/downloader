// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "./ERC20.sol";

contract Bottle is ERC20 {
constructor() ERC20('Bottled Water', 'bwater') {
     _mint(msg.sender, 100000000 * 10 ** 18);
  }
}