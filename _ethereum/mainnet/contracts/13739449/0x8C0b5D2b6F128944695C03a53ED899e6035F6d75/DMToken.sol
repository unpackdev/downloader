// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract DMToken is ERC20, ERC20Burnable {
    constructor() ERC20("Dragon Master Token", "DMT") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}