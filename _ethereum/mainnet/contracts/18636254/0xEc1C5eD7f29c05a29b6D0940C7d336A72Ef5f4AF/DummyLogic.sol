// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DummyLogic {
  address ownerAddr;

  function initialize(address owner) external {
    ownerAddr = owner;
  }

  function readOwnerAddrViaDelegateCall() external view returns (address) {
    return ownerAddr;
  }
}
