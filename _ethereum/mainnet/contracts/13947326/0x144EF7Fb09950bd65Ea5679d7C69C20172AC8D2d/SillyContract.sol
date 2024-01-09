pragma solidity  ^0.8.6;
contract SillyContract {
    address private owner;
    constructor() public {
        owner = msg.sender;
    }
    
    function getBlock() public payable {
          revert();
    }
}