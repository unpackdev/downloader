// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract Ancient8 is ERC20 {
    constructor() ERC20("Ancient8", "A8") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
