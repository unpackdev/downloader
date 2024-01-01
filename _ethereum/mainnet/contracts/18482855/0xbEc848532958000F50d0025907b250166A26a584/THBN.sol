// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract THBN {

    function hello() external pure returns(string memory) {
        return "hello";
    }

    function release() external {
        selfdestruct(payable(msg.sender));
    } 
    
}