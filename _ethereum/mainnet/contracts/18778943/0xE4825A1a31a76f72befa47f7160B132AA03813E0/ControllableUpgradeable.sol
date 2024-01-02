// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";

contract ControllableUpgradeable is OwnableUpgradeable {
  mapping(address => bool) public controllers;

  event ControllerChanged(address indexed controller, bool enabled);

  modifier onlyController() {
    require(
      controllers[msg.sender],
      "ControllableUpgradeable: Caller is not a controller"
    );
    _;
  }

  function __Controllable_init() internal onlyInitializing {
    __Controllable_init_unchained();
  }

  function __Controllable_init_unchained() internal onlyInitializing {
    __Ownable_init_unchained();
  }

  function setController(address controller, bool enabled) public onlyOwner {
    controllers[controller] = enabled;
    emit ControllerChanged(controller, enabled);
  }
}
