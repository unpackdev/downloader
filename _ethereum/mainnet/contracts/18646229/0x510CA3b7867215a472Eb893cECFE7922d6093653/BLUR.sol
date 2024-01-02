// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BLUR is ERC20 {
    constructor() ERC20(unicode"BLUR", unicode"Blur") {
        uint256 tokenSupply = 3000000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
