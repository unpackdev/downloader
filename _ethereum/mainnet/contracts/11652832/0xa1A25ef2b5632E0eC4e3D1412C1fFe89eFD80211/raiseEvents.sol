pragma solidity ^0.6.0;

contract raiseEvents {
    event GiveMeAnEvent(uint256 indexed id, string something);
    
    function callThisEvent() public {
        emit GiveMeAnEvent(1, "here am I - Let me try a longer string to see what happens too!");
    }
}