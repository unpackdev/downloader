//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Ownable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
}