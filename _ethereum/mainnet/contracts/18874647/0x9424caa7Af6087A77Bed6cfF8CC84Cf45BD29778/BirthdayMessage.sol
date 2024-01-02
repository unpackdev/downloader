// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract BirthdayMessage {
    string public message;
    mapping(address => bool) public signatories;

    constructor() {
        message = "Happy 2nd Birthday to me! (29.12.2021)";
    }

    function signMessage() public {
        signatories[msg.sender] = true;
    }

    function checkSignature(address _address) public view returns (bool) {
        return signatories[_address];
    }
}