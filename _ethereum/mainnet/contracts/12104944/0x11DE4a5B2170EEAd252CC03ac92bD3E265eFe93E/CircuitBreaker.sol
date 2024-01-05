// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";


interface IController {
  function setPublicSwap(address indexPool, bool isPublic) external;
}


contract CircuitBreaker is Ownable {
  address public controller;
  mapping(address => bool) public isApprovedAccount;

  constructor(address _controller) public Ownable() {
    controller = _controller;
  }

  function approveAccount(address account) external onlyOwner {
    isApprovedAccount[account] = true;
  }

  function disapproveAccount(address account) external onlyOwner {
    isApprovedAccount[account] = false;
  }

  function setPublicSwap(address indexPool, bool isPublic) external {
    require(isApprovedAccount[msg.sender], "Not authorized");
    IController(controller).setPublicSwap(indexPool, isPublic);
  }
}
