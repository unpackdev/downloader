// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";
import "./Ownable.sol";

contract AviatorToken is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    constructor() ERC20("Aviator", "AVI") ERC20Permit("Aviator") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}