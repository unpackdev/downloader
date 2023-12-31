// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract Store {
    string public memo;

    function reset() public {
        memo = "";
    }

    function setStorage(string memory str) public returns (string memory) {
        memo = str;
        return memo;
    }
}
