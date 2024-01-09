// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ReentrancyGuard.sol";
import "Ownable.sol";


abstract contract Controlled is Ownable {
    mapping(address=>bool) public controllers;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);

    // Authorises a controller, who can mint new IDs
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    modifier onlyController() {
        require(controllers[msg.sender], "Controlled: not controller");
        _;
    }
}