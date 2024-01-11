// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleStorage {
    uint public storedData;

    function set(uint _storedData) public {
        storedData = _storedData;
    }
}