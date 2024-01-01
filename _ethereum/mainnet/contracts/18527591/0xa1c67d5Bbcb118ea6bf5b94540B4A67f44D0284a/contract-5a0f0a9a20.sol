// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

/// @custom:security-contact hello@fafo.finance
contract FafoFinance is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("Fafo Finance", "FAFO")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 69420 * 10 ** decimals());
    }
}
