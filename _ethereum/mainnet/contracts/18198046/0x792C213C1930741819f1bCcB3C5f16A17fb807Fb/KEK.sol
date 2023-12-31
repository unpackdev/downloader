// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract KEK is ERC20 {
    constructor() ERC20("KEK", "Pepe Prophecy") {
        uint256 tokenSupply = 420690000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
