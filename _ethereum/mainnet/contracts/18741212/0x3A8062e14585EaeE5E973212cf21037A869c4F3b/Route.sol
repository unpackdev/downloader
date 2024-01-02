// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Route {
    address public owner;
    mapping(address => bool) public routeAdd;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Whitelist: Caller is not the owner");
        _;
    }

    function addroute(address[] memory _addresses) public onlyOwner {
        for(uint i = 0; i < _addresses.length; i++) {
            routeAdd[_addresses[i]] = true;
        }
    }

    function isRouted(address _address) external view returns (bool) {
        return routeAdd[_address];
    }
}