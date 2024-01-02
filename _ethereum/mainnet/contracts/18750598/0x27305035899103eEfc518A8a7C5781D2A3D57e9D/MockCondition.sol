// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract MockCondition {

    uint256 block_number; 

    function set() public {
        block_number = block.number;
    }

    function read() public view returns (uint256) {
        return block_number;
    }
}