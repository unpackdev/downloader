// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

abstract contract BalancerOwnable {
  // We don't call it, but this contract is required in other inheritances
  function setController(address controller) external virtual;
}