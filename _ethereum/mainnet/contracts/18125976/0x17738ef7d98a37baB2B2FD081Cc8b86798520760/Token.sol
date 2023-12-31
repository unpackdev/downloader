/**
SPDX-License-Identifier: MIT

https://shibariumvault.xyz/	
https://twitter.com/Shibarium_Vault
https://t.me/ShibariumVault	
*/

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract ShibariumVault is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("ShibariumVault", "SHIBVAULT") {
        _mint(msg.sender,  1000000 * (10 ** decimals())); 
    }

}
