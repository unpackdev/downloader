// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Context.sol";

contract AdminAgent is Context {

  mapping(address => bool) private _adminAgents;

  constructor(address[] memory adminAgents_) {
    for (uint i = 0; i < adminAgents_.length; i++) {
      require(adminAgents_[i] != address(0), "Invalid address");
      _adminAgents[adminAgents_[i]] = true;
    }
  }

  modifier onlyAdminAgents() {
    require(_adminAgents[_msgSender()], "Unauthorized");
    _;
  }
}