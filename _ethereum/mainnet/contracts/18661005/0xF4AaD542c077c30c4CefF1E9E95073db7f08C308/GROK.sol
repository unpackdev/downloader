// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract GROK is ERC20 {
    constructor() ERC20(unicode"GROK", unicode"GROK") {
        uint256 tokenSupply = 6900000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
