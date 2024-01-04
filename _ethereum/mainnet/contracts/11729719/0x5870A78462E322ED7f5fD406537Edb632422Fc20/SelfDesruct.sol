// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract SelfDestruct {
    function selfdest(address payable _transferTo) public payable {
        selfdestruct(_transferTo);
    }
}
