// SPDX-License-Identifier: MIT
// https://friendtips.app	
// https://t.me/FriendTipsOfficialPortal	
// https://twitter.com/_Friend_Tips_
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract FriendTips is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Friend Tips", "FIP") {
        _mint(msg.sender,  100000000000 * (10 ** decimals())); 
    }
}
