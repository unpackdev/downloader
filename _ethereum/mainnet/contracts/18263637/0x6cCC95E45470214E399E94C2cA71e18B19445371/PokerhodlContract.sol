// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract PokerhodlContract {
    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function setMessage(string memory _message) public {
        message = _message;
    }
}