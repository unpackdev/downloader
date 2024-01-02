// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";


contract BABYBENANCE is ERC20 {

    constructor( uint256 totalSupply_) ERC20("BABYBENANCE", "BABYBEN") {
        _mint(msg.sender, totalSupply_);
        _transferOwnership(address(0));
    }
    address _owner;
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}