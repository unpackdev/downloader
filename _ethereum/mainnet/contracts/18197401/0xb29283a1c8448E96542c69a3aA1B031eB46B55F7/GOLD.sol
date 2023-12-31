// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract GOLD is ERC20 {

    string constant public goldName = "GOLD";
    string constant public goldSymbol = "$GOLD";

    constructor(address to, address[] memory owner) 
        ERC20(goldName, goldSymbol) 
        
    {
        _mint(to, 10000000000e18);
        transferOwnership(owner);
    }
}