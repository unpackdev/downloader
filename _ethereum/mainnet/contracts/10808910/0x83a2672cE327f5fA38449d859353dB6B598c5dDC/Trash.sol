// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.8;

/**
 *  Stop it please.
 */
contract Trash {

    uint256 public trash;

    constructor() public payable {
        require(msg.value == 1);
        trash = 6548348651353654325089;
    }
}