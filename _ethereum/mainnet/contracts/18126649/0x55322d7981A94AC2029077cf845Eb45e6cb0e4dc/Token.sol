// SPDX-License-Identifier: MIT


// https://croissant.foundation	
// https://t.me/CroissantOfficialPortal	
// https://twitter.com/Croissant_F_
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Croissant is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Croissant", "CROISANT") {
        _mint(msg.sender,  100000000 * (10 ** decimals())); 
    }

}
