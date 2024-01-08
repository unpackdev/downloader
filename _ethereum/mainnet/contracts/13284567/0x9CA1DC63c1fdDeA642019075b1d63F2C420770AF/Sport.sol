// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Sport is ERC20, ERC20Burnable {
    constructor() ERC20("Sport", "SPORT") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}
