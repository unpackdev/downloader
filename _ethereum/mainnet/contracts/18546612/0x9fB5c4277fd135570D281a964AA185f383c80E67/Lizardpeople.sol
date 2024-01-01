// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract Lizardpeople is ERC20 { 

    string constant public lizName = "Lizardpeople";
    string constant public lizSymbol = "$LZRD";

    constructor(address to) 
    ERC20(lizName, lizSymbol) { 
        _mint(to, 1000000000e18);
    }
}