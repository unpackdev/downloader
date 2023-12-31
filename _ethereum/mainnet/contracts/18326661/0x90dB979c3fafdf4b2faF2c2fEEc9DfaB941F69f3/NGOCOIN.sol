// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";

contract NGO_COIN is ERC20 {
    constructor() ERC20("NGO COIN", "NGO") {
        uint256 totalSupply = 1310000000 * 10 ** 18; // 1,310,000,000 tokens with 18 decimals
        _mint(msg.sender, totalSupply);
    }
}
