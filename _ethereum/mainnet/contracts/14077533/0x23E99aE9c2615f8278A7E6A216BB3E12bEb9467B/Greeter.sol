// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";

contract Greeter {
    string private greeting;
    string private greetinger;

    constructor(string memory _greeting, string memory _greetinger) {
        console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
        greetinger = _greetinger;
    }

}
