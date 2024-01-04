// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

contract Timer {
  uint256 private currentTime;

  constructor() public {
    currentTime = now;
  }

  function setCurrentTime(uint256 time) external {
    currentTime = time;
  }

  function getCurrentTime() public view returns (uint256) {
    return currentTime;
  }
}
