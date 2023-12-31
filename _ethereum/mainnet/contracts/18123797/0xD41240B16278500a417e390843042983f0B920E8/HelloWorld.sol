// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    string private greetingMessage;

    constructor() {
        greetingMessage = "Hello, World!";
    }

    function setGreeting(string memory _newGreeting) public {
        greetingMessage = _newGreeting;
    }

    function getGreeting() public view returns (string memory) {
        return greetingMessage;
    }
}