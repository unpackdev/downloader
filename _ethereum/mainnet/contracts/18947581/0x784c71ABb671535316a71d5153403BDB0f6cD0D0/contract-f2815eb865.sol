// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/// @custom:security-contact https://t.me/PUSSYERC2
contract PUSSY is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("PUSSY", "PUSSY")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}
