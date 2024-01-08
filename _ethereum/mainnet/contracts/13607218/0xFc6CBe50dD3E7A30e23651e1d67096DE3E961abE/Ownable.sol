// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Ownable {
    address private _owner;
    address private _newOwner;

    event OwnershipTransferProposal(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "OW3");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "AD2");
        emit OwnershipTransferProposal(_owner, newOwner);
        _newOwner = newOwner;
    }

    function acceptOwnership() external virtual {
        require(msg.sender == _newOwner, "OW4");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }
}
