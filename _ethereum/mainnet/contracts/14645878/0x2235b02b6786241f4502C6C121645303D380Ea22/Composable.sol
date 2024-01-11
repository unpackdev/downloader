// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Composable is Ownable {
    mapping(address => bool) components;

    modifier onlyComponent() {
       if (!components[msg.sender]) revert();
        _;
    }

    function addComponent(address component, bool value) external onlyOwner {
        components[component] = value;
    }

    function isComponent(address _address) public view returns (bool) {
        return components[_address];
    }

}