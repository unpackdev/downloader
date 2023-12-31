//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function say() public view returns (string memory) {
        return greeting;
    }

    function setSaying(string memory _greeting) public {
        greeting = _greeting;
    }
}
