// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  ____  _       _ _     _           
 |  _ \(_) __ _(_) |__ | | ___  ___ 
 | | | | |/ _` | | '_ \| |/ _ \/ __|
 | |_| | | (_| | | |_) | |  __/\__ \
 |____/|_|\__, |_|_.__/|_|\___||___/
          |___/ 
 **/

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Digibles is ERC20Burnable, Ownable  {
    constructor() ERC20("Digibles", "DGBL") {
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
    }
}
