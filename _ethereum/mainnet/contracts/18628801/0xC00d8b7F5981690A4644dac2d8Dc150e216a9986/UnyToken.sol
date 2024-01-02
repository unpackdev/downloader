/*
https://twitter.com/unyoncapital
https://www.unyon.capital/
*/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC721.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract UnyToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Unyon Token", "Uny") Ownable(msg.sender) { 
        _mint(msg.sender, 999000 * 10**decimals());
    }
}

