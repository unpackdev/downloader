// SPDX-License-Identifier: MIT
// https://twitter.com/Real_Pepe_Frog https://t.me/RealPepeFrogEntry https://realpepefrog.com	
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract RealPepeFrog is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Real Pepe Frog", unicode"лягушка") {
        _mint(msg.sender,  100000000 * (10 ** decimals())); 
    }
}
