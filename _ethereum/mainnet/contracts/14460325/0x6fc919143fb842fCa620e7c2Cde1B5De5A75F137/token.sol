// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20.sol";


contract Staurant is ERC20 {
    
    constructor() ERC20("Delae", "DEE") {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }
}