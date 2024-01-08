// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC20Burnable.sol";

contract Secuaa is ERC20Burnable {

    constructor() ERC20("Secuaa", "SECU") {
        _mint(msg.sender, 512000000000000000000000000);
    }

}

