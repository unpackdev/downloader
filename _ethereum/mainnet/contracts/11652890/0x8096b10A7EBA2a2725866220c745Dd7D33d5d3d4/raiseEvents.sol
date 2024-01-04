pragma solidity ^0.6.0;

contract raiseEvents {
    event GiveMeAnEvent(uint256 indexed id, uint256 someRandomNumber, string something);
    
    function callThisEvent() public {
        emit GiveMeAnEvent(1, 1337, "here am I - Let me try a longer string to see what happens too!");
    }
}