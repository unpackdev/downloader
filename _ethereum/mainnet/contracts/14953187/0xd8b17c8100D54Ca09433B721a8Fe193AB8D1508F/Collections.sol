//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

library Collections {
    struct LinkedList {
        mapping(uint256 => uint256) nodeToValue;
        mapping(uint256 => uint256) nodeLinks;
    }
}
