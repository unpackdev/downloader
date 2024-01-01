// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract LightningShit is ERC20 {
    constructor() ERC20("Lightning Shit", "LTS") {
        _mint(msg.sender, 21000000 * 10 ** 18);
    }
}