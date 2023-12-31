// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BEAR is ERC20 {
    constructor() ERC20("BEAR", "The Bear") {
        uint256 tokenSupply = 1000000000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
