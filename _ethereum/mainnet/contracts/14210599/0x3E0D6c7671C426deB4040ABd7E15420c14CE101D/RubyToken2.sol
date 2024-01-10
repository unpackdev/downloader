// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract RubyToken2 is ERC20{
   constructor() ERC20("RubyToken2", "RBY2") {
       _mint(0xa82cDDA842a158c54d03A62F9d9391964748706E, 240000000000000000000000000);
   }
}