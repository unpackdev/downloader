// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IAdminController.sol";
import "./Ownable.sol";

abstract contract AdminController is IAdminController, Ownable {
    mapping(address => bool) public _admins;

    constructor() {
        _admins[msg.sender] = true;
    }    

    function isAdmin(address to) public view returns (bool) {
        return _admins[to];
    }

    modifier adminOnly() {
        require(_admins[msg.sender] || msg.sender == owner(), "Not authorised");
        _;
    }

    function setAdmins(address to, bool value) public adminOnly {
        _admins[to] = value;
    }
}