// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract POG is ERC20 {
    constructor() ERC20("POG", "Pog Coin") {
        uint256 tokenSupply = 1000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
