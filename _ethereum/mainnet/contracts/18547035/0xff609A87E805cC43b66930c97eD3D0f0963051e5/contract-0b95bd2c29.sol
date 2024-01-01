// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Bull is ERC20, ERC20Burnable {
    constructor() ERC20("Bull", "BULL") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}
