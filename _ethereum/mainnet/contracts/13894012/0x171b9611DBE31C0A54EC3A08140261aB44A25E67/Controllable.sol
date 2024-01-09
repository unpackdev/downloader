// SPDX-License-Identifier: CC0
pragma solidity ^0.8.7;

import "./Ownable.sol";

contract Controllable is Ownable {

    mapping(address => bool) controllers;

    function addControllers(address[] calldata newControllers) external onlyOwner {
        for (uint i=0; i < newControllers.length; i++) {
            controllers[newControllers[i]] = true;
        }
    }

    function removeController(address toDelete) external onlyOwner {
        controllers[toDelete] = false;
    }

    function addController(address newController) external onlyOwner
    {
        controllers[newController] = true;
    }

    modifier onlyControllers() {
        require(controllers[msg.sender], "Not Authorized");
        _;
    }


}