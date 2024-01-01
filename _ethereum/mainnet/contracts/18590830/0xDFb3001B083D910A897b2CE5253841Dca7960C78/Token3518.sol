// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Token3518 is ERC20 {
    constructor() ERC20("3518", "3518") {
        _mint(msg.sender, 1e27);
    } 
}
