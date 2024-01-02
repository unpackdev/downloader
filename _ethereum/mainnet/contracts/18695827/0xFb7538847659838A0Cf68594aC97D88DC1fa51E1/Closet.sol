// SPDX-License-Identifier: MIT
// your $scissor is safe in here, this is
// where all $scissor should and will belong
pragma solidity 0.8.20;

contract Closet{
    address public owner;
    constructor(){
        owner = msg.sender;
    }
    receive() external payable {}
    fallback() external payable{}
}