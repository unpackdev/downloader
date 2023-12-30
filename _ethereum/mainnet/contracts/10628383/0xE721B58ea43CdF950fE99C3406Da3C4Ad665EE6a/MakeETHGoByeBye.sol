//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.7.0;

contract MakeETHGoByeBye {
    receive() external payable { 
        new ETHGoByeBye{value: msg.value}();
    }
}

contract ETHGoByeBye {
    constructor() public payable { 
        selfdestruct(address(uint160(address(this))));
    }
}