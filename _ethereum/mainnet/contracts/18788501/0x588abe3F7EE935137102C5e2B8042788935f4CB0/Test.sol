// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {

    // function test(uint64 x) pure public returns (bytes32) {
    //     return bytes32(bytes8(x));
    // }

    // function test2(address x) pure public returns (bytes32) {
    //     return bytes32(bytes20(x));
    // }

    function baseFee() view public returns (uint) {
        return block.basefee;
    }
}