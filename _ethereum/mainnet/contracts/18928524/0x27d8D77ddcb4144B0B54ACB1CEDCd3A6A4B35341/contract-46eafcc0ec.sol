// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/// @custom:security-contact https://t.me/Hugoinu
contract HUGOINU is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("HUGO INU", "HUG")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 99999999 * 10 ** decimals());
    }
}
/// https://hugoinu.online