// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract AnimeToken is ERC20 {
    
    constructor() ERC20("ANIME", "ANIME") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}