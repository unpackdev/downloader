// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./console.sol";

contract Whitelist is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(address => uint) public whitelist;
    mapping(address => uint) public freelist;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

// view

    function getCount(address _addr) public view returns (uint) {
        return whitelist[_addr];
    }

    function getCountFree(address _addr) public view returns (uint) {
        return freelist[_addr];
    }

// admin setting

    function setMany(address[] memory _new, uint _count) public onlyRole(MINTER_ROLE) {
        for (uint i = 0;i<_new.length;i++){
            whitelist[_new[i]] = _count;
        }
    }

    function setManyFree(address[] memory _new, uint _count) public onlyRole(MINTER_ROLE) {
        for (uint i = 0;i<_new.length;i++){
            freelist[_new[i]] = _count;
        }
    }

    function set(address _addr, uint _count) public onlyRole(MINTER_ROLE) {
        whitelist[_addr] = _count;
    }

    function setFree(address _addr, uint _count) public onlyRole(MINTER_ROLE) {
        freelist[_addr] = _count;
    }

// claim

    function decrease(address _addr, uint _count) public onlyRole(MINTER_ROLE) {
        require (whitelist[_addr] >= _count, "can't decrease wl count");
        whitelist[_addr] = whitelist[_addr] - _count;
    }

    function decreaseFree(address _addr, uint _count) public onlyRole(MINTER_ROLE) {
        require(freelist[_addr] >= 0, "Not on the free list");
        freelist[_addr] = freelist[_addr] - _count;
    }



}