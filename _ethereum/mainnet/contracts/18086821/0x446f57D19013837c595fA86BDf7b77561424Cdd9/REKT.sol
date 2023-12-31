// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract REKT is ERC20 {

    string constant public rektName = "REKT";
    string constant public rektSymbol = "$REKT";

    constructor(address to, address[] memory owner) 
        ERC20(rektName, rektSymbol) 
        
    {
        _mint(to, 10000000000e18); 
        transferOwnership(owner);
    }
}