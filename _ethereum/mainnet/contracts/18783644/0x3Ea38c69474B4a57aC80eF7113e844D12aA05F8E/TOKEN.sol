
    // SPDX-License-Identifier: MIT
    // dfsfssdfdddasdsaddsfdssdfsdsdfsdfs
    pragma solidity ^0.8.20;
    
    contract TOKEN {
        string private greeting;
    
        constructor() {
            greeting = "Hello, World!";
        }
    
        function getGreeting() public view returns (string memory) {
            return greeting;
        }
    
        function setGreeting(string memory _newGreeting) public {
            greeting = _newGreeting;
        }
    }