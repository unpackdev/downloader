// https://gogcoin.xyz	
// https://t.me/GOGCoinPortal	
// https://twitter.com/GOG_Coin_
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract GOGCoin is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("GOG Coin", "GOG") {
        _mint(msg.sender,  1000000000 * (10 ** decimals())); 
    }

}
