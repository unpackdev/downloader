// 🏎️ Lambo Finance: The Ultra-Fast Meme Coin Racing to the Moon!
// "Fasten Your Seatbelts – Next Stop, the Moon!"
// Lambo Finance is not just a token; it's a statement.
// For those who dream big and hustle hard, Lambo Finance is your fuel. 
// We're all about speed, style, and breaking the mold.
// No tax, no ownership to renounce, no rug, pure pump!

// Web: https://lamboeth.finance
// Telegram: https://t.me/lamboeth
// X: https://x.com/lamboeth

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

contract LamboFinance is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20(unicode"🏎️ lamboeth.finance", "LAMBO") ERC20Permit("LAMBO") {
        _mint(msg.sender, 42000000 * 10 ** 18);
    }
}
