// SPDX-License-Identifier: MIT
/*
                                 
 _______ _______ _______ _______ 
|\     /|\     /|\     /|\     /|
| +---+ | +---+ | +---+ | +---+ |
| |   | | |   | | |   | | |   | |
| |P  | | |e  | | |p  | | |a  | |
| +---+ | +---+ | +---+ | +---+ |
|/_____\|/_____\|/_____\|/_____\|
                                 



Written By 
__   _______ 
\ \ / /  _  |
 \ V /| | | |
 /   \| | | |
/ /^\ \ \_/ /
\/   \/\___/ 
             
             

                


*/


pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";

/// @custom:security-contact infosec@Pepa.com
contract Pepa is ERC20, ERC20Permit, Ownable {
    constructor(address initialOwner)
        ERC20("Pepa", "Pepa")
        ERC20Permit("Pepa")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}