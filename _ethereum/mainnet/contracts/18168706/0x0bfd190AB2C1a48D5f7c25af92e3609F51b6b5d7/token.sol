// SPDX-License-Identifier: MIT
// https://bananaahah.com	https://t.me/Bananaahah https://x.com/bananaah_ah

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract BABABA is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Banana-ah-ah", unicode"BABABA") {
        _mint(msg.sender,  1000000000 * (10 ** decimals())); 
    }
}
