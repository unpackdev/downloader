// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./Timer.sol";

abstract contract Testable {
  address public timerAddress;

  constructor(address _timerAddress) internal {
    timerAddress = _timerAddress;
  }

  modifier onlyIfTest {
    require(timerAddress != address(0x0));
    _;
  }

  function setCurrentTime(uint256 time) external onlyIfTest {
    Timer(timerAddress).setCurrentTime(time);
  }

  function getCurrentTime() public view returns (uint256) {
    if (timerAddress != address(0x0)) {
      return Timer(timerAddress).getCurrentTime();
    } else {
      return now;
    }
  }
}
