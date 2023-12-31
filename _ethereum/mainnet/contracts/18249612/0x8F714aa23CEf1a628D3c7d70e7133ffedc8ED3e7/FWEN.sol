// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract FWEN is ERC20 {
    constructor() ERC20("FWEN", "FWEN") {
        _mint(msg.sender, 1_000_000_000_000e18);
    }
}
