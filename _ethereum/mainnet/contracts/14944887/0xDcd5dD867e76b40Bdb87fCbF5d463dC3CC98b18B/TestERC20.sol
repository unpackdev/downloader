// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract TestERC20 is Ownable, ERC20 {
    struct A {
        string name;
        uint age;
        bytes32 hash;
        bytes message;
    }

    uint[] numbers;
    bytes[] bytesArray;
    A a;
    address addr;
    uint number;

    // test for verification of contract
    constructor(
        string memory name,
        string memory symbol,
        address addr_,
        uint number_,
        uint[] memory numbers_,
        bytes[] memory bz,
        A[] memory aArray_
    )ERC20(name, symbol){
        a = aArray_[1];
        addr = addr_;
        number = number_;
        numbers = numbers_;
        bytesArray = bz;
    }

    function mint(uint amount) external onlyOwner {
        _mint(msg.sender, amount);
    }
}
