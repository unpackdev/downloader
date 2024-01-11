// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransfered(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_msgSender() == owner(), "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Owner cannot be zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner();
        _owner = newOwner;
        emit OwnershipTransfered(oldOwner, newOwner);
    }
}
