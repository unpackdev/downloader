// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract Timestamp {
    event ShowTimestamp(uint _timestamp);

    function getNowTimestamp() public view returns (uint) {
        return now;
    }

    function timestamp() public {
        emit ShowTimestamp(now);
    }
}