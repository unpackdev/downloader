/**
* @author 2024cash.eth
* @title 2024 CASH token
* Website: https://2024.cash
* Telegram: @BeRich2024cash
* X: https://twitter.com/2024_cash
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./ERC20FlashMint.sol";
import "./Ownable.sol";

contract TokenCash is ERC20, ERC20Burnable, ERC20Permit, ERC20FlashMint, Ownable {
    constructor(address initialOwner)
        ERC20("2024", "2024CASH")
        ERC20Permit("2024")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 420_069_000_002_024 * 10 ** decimals());
    }
}