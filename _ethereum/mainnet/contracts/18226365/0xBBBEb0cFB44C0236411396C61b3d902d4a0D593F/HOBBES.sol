// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract HOBBES is ERC20 {
    constructor() ERC20(unicode"HOBBES 2.0", unicode"Hobbes 2.0") {
        uint256 tokenSupply = 1000000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
