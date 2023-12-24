// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
Hello chads. Join EOM_calls for early ca and calls. I have good gambles everyday so don't miss it. 

https://t.me/EOM_calls


This ca was created for the purpose of marketing my channel <3
*/

contract EOM {
    string public name = "@EOM_calls";
    string public symbol = "EOM";
    uint256 public totalSupply = 696969696900000000000000000;
    uint8 public decimals = 18;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}