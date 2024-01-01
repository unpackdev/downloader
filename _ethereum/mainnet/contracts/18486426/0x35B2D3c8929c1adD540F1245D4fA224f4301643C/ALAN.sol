/*
    Alan Wake 2 ($ALAN) 
    https://alanwake2.tech	
    https://t.me/AlanWake2Portal	
    https://twitter.com/Alan_Wake_2
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract AlanWake2 is ERC20 {
    constructor() ERC20("Alan Wake 2", "ALAN") {
        _mint(msg.sender, 666666666 * 10**18);
    }
}