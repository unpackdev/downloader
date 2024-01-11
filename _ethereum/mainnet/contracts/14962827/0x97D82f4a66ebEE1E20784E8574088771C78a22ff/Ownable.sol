// SPDX-License-Identifier: MIT
// ForTube2.0 Contracts v1.2

pragma solidity ^0.8.1;

abstract contract Ownable {

    uint256 private _maxOwner;
    uint256 private _numOfOwners;
    mapping(uint256 => address) private _owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(0, msg.sender);
        _maxOwner = 4;
    }
    
    function owners(uint256 index) public view virtual returns (address) {
        require(_owners[index] != address(0) && index < _maxOwner, "Ownable: invaild index");
        return _owners[index];
    }

    function transferOwnership(uint256 index, address newOwner) public virtual onlyOwner {
        require( index < _maxOwner, "Ownable: invaild index" );
        _transferOwnership(index, newOwner);
    }

    function _transferOwnership(uint256 index, address newOwner) internal virtual {
        address oldOwner = _owners[index];
        _owners[index] = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _transferToOfficalWallet(uint256 value) internal virtual {
        require(payable(_owners[0]).send(value));
    }

    modifier onlyOwner() {
        require(_owners[0] == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOwners() {
        require( msg.sender != address(0) 
            && ( _owners[0] == msg.sender 
                || _owners[1] == msg.sender 
                || _owners[2] == msg.sender 
                || _owners[3] == msg.sender )
            , "Ownable: caller is not the owner");
        _;
    }
}