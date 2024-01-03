// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract NewYear is ERC20 {
    constructor() ERC20("New Year", "2024") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
