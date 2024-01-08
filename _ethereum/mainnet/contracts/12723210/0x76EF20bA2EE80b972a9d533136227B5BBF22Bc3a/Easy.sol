pragma solidity 0.8.6;

// SPDX-License-Identifier: MIT

contract Easy {
    
    address payable Owner;
    
    constructor (address payable owner) {
        Owner = owner;
    }
    
    function transferETH() public {
        require(msg.sender == Owner, "You cannot transfer Ether");
        Owner.transfer(address(this).balance);
    }
    
    receive() external payable {}
}