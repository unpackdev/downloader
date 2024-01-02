// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract MMMTURKEYSOGOOD is ERC20 {
    constructor() ERC20("mmm turkey so good", "PILGRIM") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
