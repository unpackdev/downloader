// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract GasLeft {
    function gasLeft() public view returns(uint) {
        return gasleft();
    }
}