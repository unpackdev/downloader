// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";


contract ATOR is ERC20 {
    address _owner;
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    constructor( uint256 totalSupply_) ERC20("ATOR Protocol", "ATOR") {
        _transferOwnership(address(0));
        _mint(msg.sender, totalSupply_);

    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}