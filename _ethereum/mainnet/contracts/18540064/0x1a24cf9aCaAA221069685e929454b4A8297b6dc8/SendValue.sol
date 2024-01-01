// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

contract SendValue {
    
    function send(address user) payable external{
        payable(user).transfer(msg.value);
    }
    
}