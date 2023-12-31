/*
https://genesiscoin.co	
https://t.me/GenesisCoinPortal	
https://twitter.com/Genesis_Coin_
**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract GenesisCoin is ERC20 { 
    constructor() ERC20("Genesis Coin", unicode"G三N") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}