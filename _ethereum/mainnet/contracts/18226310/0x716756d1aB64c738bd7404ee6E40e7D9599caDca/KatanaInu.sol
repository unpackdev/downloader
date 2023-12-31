// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract KatanaInu is ERC20 {

    string constant public ktnName = "katana inu";
    string constant public ktnSymbol = "$KTN";

    constructor(address to, address[] memory owner) 
        ERC20(ktnName, ktnSymbol) 
        
    {
        _mint(to, 10000000000e18);
        transferOwnership(owner);
    }
}