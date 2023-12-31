// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract HOPE2 is ERC20 {
    constructor() ERC20(unicode"HOPE 2.0", unicode"Hopium 2.0") {
        uint256 tokenSupply = 1000000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
