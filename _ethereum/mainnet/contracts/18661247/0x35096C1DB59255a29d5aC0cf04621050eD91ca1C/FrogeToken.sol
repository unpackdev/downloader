// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract FrogeToken is ERC20 {
    constructor() ERC20(unicode"FROGE", unicode"FROGE") {
        uint256 tokenSupply = 690420000000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
