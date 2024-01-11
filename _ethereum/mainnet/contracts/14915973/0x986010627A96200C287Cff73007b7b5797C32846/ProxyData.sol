// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProxyData {
  address implementation_;
  address public admin;

  constructor() {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function transferOwnership(address newOwner) external {
    require(msg.sender == admin);
    admin = newOwner;
  }
}
