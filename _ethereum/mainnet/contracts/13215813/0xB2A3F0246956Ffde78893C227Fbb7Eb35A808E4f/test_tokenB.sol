// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "./ERC20.sol";

contract TestTokenB is ERC20 {
    constructor(uint initialSupply) ERC20("TestTokenB", "TESTB") {
        _mint(msg.sender, initialSupply);
    }
}
