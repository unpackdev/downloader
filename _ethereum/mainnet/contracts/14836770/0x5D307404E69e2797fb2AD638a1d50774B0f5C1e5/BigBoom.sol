// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract BigBoom is ERC20, Ownable {
    uint256 _totalSupply = 1 * 1e8 * 1e18; // 0.1 Billion

    constructor() ERC20("Big Boom", "BIGBOOM") {
        _mint(msg.sender, _totalSupply);
    }
}
