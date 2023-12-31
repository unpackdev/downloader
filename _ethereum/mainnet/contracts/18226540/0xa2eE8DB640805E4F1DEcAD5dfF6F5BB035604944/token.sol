// SPDX-License-Identifier: MIT
// https://Post.Tech	https://t.me/POSTTECH_ERC20
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract POST is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("POST.TECH", "POST") {
        _mint(msg.sender,  10000000000 * (10 ** decimals())); 
    }
}
