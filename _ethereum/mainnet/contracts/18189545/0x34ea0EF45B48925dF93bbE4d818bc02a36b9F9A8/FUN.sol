// SPDX-License-Identifier: MIT
// https://thisisfun.xyz	
// https://t.me/ThisisFunPortal

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Fun is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("This is Fun", unicode"FUN") {
        _mint(msg.sender,  1000000000 * (10 ** decimals())); 
    }
}
