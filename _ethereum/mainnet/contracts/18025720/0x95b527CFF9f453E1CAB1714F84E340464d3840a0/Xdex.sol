
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract XDex is ERC20 { 
    constructor() ERC20("X Dex", "XDEX") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}