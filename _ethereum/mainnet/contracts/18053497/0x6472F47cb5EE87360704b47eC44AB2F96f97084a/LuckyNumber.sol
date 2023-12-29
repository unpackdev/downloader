// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract LuckyNumber {

    event NewNumber(uint256 number);
    
    function broadcastNumber(uint256 _number) external {
        emit NewNumber(_number);
    }
}