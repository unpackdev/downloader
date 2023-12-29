// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./ERC20FlashMint.sol";
import "./Ownable.sol";

contract MacksCoin is ERC20, ERC20Burnable, ERC20Permit, ERC20FlashMint, Ownable {
    constructor(address initialOwner)
        ERC20("Macks Coin", "MACKS")
        ERC20Permit("Macks Coin")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }
}
