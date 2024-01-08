pragma solidity ^0.8.4;

import "./TimelockControllerUpgradeable.sol";

contract UnlockProtocolTimelock is TimelockControllerUpgradeable {
  function initialize (
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors
  ) public initializer {
    __TimelockController_init(minDelay, proposers, executors);
  }
}