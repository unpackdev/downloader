//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;
    event LogTransferredOwnership(address indexed oldOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Contract need an owner");
        require(newOwner != _owner, "Same owner");
        address oldOwner = _owner;
        _owner = newOwner;
        emit LogTransferredOwnership(oldOwner, newOwner);
    }
}
