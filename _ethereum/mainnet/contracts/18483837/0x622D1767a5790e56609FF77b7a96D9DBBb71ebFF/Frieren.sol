// SPDX-License-Identifier: MIT
/**

Website https://frieren.vip	
TG https://t.me/FrierenOfficialPortal	
Twitter https://twitter.com/Frieren_Elf_

**/
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Frieren is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Frieren", "FRIEREN") {
        _mint(msg.sender,  10000000 * (10 ** decimals())); 
    }

}
