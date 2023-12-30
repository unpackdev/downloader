// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

contract ForceEth {
    constructor(address payable _to) public payable {
        selfdestruct(_to);
    }
}
