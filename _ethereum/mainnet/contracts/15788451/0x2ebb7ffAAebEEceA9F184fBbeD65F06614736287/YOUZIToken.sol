// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract YOUZIToken is ERC20 {
    constructor() ERC20("You Zi Token", "YOUZI") {
        _mint(msg.sender, 1000000 * (10 ** 18));
    }
}
