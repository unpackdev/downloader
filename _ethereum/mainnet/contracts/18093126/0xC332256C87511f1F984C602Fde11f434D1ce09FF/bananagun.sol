//https://bananagun.io/
//https://twitter.com/BananaGunBot
//https://t.me/bananagunannouncements

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./Ownable.sol";

contract BananaGunCoin is ERC20, Ownable {
    constructor() ERC20("banana gun coin", "banana") {
        uint256 initialSupply = 100000000 * 10 ** 18; // 100,000,000 tokens with 18 decimals
        _mint(msg.sender, initialSupply);
    }
}
