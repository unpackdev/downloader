// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract AstroRealSmurfCatX is ERC20 { 
    constructor() ERC20("AstroRealSmurfCatX", unicode"Астрошайлушайс") { 
        _mint(msg.sender, 500_000_000 * 10**18);
    }
}