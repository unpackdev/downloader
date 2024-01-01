//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

contract Hobby {
    string private hobby;

    constructor(string memory _hobby) {
        hobby = _hobby;
    }

    function say() public view returns (string memory) {
        return hobby;
    }

    function setHobby(string memory _hobby) public {
        hobby = _hobby;
    }
}
