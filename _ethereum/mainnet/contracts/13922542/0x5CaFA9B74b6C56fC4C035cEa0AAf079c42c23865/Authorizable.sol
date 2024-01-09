// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";

contract Authorizable is Ownable {
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender);
        _;
    }

    function addAuthorized(address _toAdd) external onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) external onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}