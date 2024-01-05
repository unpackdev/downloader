// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMathUpgradeable.sol";

library ComputeCyclesHeldLib {
  using SafeMathUpgradeable for *;

  function _computeCyclesHeld(
    uint256 cycleEnd,
    uint256 interval,
    uint256 _cyclesHeld,
    uint256 currentTimestamp
  ) internal pure returns (uint256, uint256) {
    uint256 cyclesHeld;
    if (cycleEnd == 0) cycleEnd = currentTimestamp + interval;
    else if (currentTimestamp > cycleEnd) {
      uint256 diff = currentTimestamp.sub(cycleEnd);
      uint256 intervals = diff.div(interval);
      if (intervals > 0) {
        if (intervals.mul(interval) == diff) intervals--;
      }
      uint256 cyclesMissed = intervals.add(1);
      cycleEnd = cyclesMissed.mul(interval).add(cycleEnd);
      cyclesHeld = cyclesHeld.add(cyclesMissed);
    }
    cyclesHeld = cyclesHeld.add(_cyclesHeld);
    return (cycleEnd, cyclesHeld);
  }
}
