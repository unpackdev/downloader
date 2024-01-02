// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract THBN {

    function hello() external pure returns(string memory) {
        return "hello";
    }

    function release() external {
        selfdestruct(payable(msg.sender));
    } 
    
}