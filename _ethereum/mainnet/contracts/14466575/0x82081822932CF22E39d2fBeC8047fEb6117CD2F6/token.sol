// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20.sol";


contract ScholeumToken is ERC20 {
    
    constructor() ERC20("Scholeum", "SCLM") {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }
}