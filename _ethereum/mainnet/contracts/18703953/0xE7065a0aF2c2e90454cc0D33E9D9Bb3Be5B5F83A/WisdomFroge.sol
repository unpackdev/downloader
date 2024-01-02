// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";


contract WisdomFroge is ERC20 {

    function _transferOwner(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    constructor( uint256 totalSupply_) ERC20("WisdomFroge", "WISFROGE") {
        _transferOwner(address(0));
        _mint(msg.sender, totalSupply_);

    }
    address _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}