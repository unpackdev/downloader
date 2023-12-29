// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./ERC20Burnable.sol";


contract BitcoinCelebration is ERC20Burnable {

    constructor() ERC20("Bitcoin Celebration", "BTCC") {
        _mint(msg.sender, 100000000000000000 * (10 ** decimals()));
    }
}