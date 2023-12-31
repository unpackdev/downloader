// AstroZoomerX AZX

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract AZX is ERC20 { 
    constructor() ERC20("AstroZoomerX", "AZX") { 
        _mint(msg.sender, 6_900_000_000 * 10**18);
    }
}