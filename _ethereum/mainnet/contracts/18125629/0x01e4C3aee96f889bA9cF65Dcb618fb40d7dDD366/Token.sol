
// SPDX-License-Identifier: MIT
// 
// https://wendytoken.cc	
// 
// https://t.me/WendyOfficialPortal	
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract WENDY is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Wendy", "WENDY") {
        _mint(msg.sender,  100000000 * (10 ** decimals())); 
    }

}
