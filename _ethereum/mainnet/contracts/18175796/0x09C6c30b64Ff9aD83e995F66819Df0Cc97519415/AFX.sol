// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract AKX is ERC20 { 
    constructor() ERC20("AstroKekeX", "AKX") { 
        _mint(msg.sender, 420_000_000 * 10**18);
    }
}