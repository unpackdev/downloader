// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract TKT is ERC20, Ownable{
    constructor() ERC20("TKT", "azuki.looksrare.team"){}
    
    function addtkt(address[] memory addr) public onlyOwner {
        require(addr.length !=0);
        for (uint i=0; i < addr.length; i++) {
            _mint(addr[i], 1*10**18);
        }
    }
}