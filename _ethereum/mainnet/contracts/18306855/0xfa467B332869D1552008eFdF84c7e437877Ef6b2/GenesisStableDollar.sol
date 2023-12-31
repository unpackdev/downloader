/*
    Stable, Safe, Secured Maketh Genesis Stable Dollar $GSD
    
    https://genesisstabledollar.com	
    
    https://t.me/GenesisStableDollar	
    
    https://twitter.com/GenesisStableD
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract GenesisStableDollar is ERC20 {
    constructor() ERC20("Genesis Stable Dollar", "GSB") {
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}