// https://t.me/SHIBAGRAMPortal	https://twitter.com/SHIBAGRAM_ https://shibagram.co	
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract SHIBAGRAM is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("SHIBAGRAM", "SHIGRAM") {
        _mint(msg.sender,  1000000000 * (10 ** decimals())); 
    }

}