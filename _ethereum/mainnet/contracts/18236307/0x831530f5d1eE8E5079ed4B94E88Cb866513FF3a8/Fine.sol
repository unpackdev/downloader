/**

Telegram: https://t.me/FINEerc 

**/

// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8;
 
contract Fine {
 
string message = "Fine Or not";
 
function contractGreeting() public view returns(string memory) {
return message;
}
}