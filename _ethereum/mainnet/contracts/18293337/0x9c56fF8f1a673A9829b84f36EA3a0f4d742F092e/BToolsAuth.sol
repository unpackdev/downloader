pragma solidity ^0.8.16;

// this contract serves as auth system for Blockchain Tool apps
contract BToolsAuth {

    mapping(address => string) public usernames;

    constructor() public {
    }

     function setUsername(string memory _username) public {
          usernames[msg.sender] = _username;
     }   
}