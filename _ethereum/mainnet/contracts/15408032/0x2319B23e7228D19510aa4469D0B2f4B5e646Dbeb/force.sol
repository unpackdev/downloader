// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract MoonFORCE is ERC20 {
    constructor() ERC20("MoonFORCE", "FORCE") {
        _mint(msg.sender, 4000000000 * 10 ** decimals());
    }
}