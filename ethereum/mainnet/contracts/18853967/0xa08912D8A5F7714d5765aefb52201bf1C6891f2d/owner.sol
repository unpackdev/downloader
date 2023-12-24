// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owner {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(isOwner(), "You are not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }


    function getOwner() public view returns (address) {
        return _owner;
    }

}
