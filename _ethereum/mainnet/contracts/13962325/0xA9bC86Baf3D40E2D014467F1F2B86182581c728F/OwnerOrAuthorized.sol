// SPDX-License-Identifier: None

// Created by 256bit.io - 2021/2022

pragma solidity ^0.8.0;

import "Ownable.sol";

contract OwnerOrAuthorized is Ownable {
    mapping(address => bool) private _authorized;

    event AuthorizationAdded(address indexed addressAdded);
    event AuthorizationRemoved(address addressRemoved);

    constructor() Ownable() {
        _authorized[msg.sender] = true;
    }

    /**
     * @dev Throws if called by any account other than an authorized user (includes owner).
     */
    modifier onlyAuthorized() {
        require(
            checkAuthorization(_msgSender()),
            "OwnOwnerOrAuthorized: caller is not authorized"
        );
        _;
    }

    function addAuthorization(address _address) public onlyOwner {
        _authorized[_address] = true;
        emit AuthorizationAdded(_address);
    }

    function removeAuthorization(address _address) public {
        require(
            owner() == _msgSender() || _authorized[_address] == true,
            "OwnOwnerOrAuthorized: caller is not authorized"
        );
        delete _authorized[_address];
        emit AuthorizationRemoved(_address);
    }

    function checkAuthorization(address _address) public view returns (bool) {
        return owner() == _address || _authorized[_address] == true;
    }
}
