// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./LibAppStorage.sol";

contract Modifiers {
    modifier onlyOneBlock() {
        mapping(uint256 => mapping(address => bool)) storage transactionHistory = LibAppStorage._diamondStorage().transactionHistory;
        require(
            !transactionHistory[block.number][tx.origin],
            "Pilgrim: one block, one function"
        );
        require(
            !transactionHistory[block.number][msg.sender],
            "Pilgrim: one block, one function"
        );

        _;

        transactionHistory[block.number][tx.origin] = true;
        transactionHistory[block.number][msg.sender] = true;
    }
}
