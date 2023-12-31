// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract SONIC is ERC20 {

    string constant public sonicName = "SONIC";
    string constant public sonicSymbol = "$SONIC";

    constructor(address to, address[] memory owner) 
        ERC20(sonicName, sonicSymbol) 
        
    {
        _mint(to, 10000000000e18);
        transferOwnership(owner);
    }
}