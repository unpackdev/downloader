// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract SimpleContract {
    uint256 public data;

    function setData(uint256 _data) public {
        data = _data;
    }

    function getData() public view returns (uint256) {
        return data;
    }
}