// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";


contract AI12Studio is ERC20 {

    constructor( uint256 totalSupply_) ERC20("AI12Studio", "AI12") {
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