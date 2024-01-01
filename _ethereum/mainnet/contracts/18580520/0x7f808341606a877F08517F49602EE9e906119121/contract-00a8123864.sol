// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract VERTICALONOFF is ERC20 {
    constructor() ERC20("VERTICAL ON OFF", "VOO") {
        _mint(msg.sender, 700 * 10 ** decimals());
    }
}
