// SPDX-License-Identifier: MIT
// БАНАН
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Banana is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20(unicode"банан", unicode"БАНАН") {
        _mint(msg.sender,  1000000000 * (10 ** decimals())); 
    }

}
