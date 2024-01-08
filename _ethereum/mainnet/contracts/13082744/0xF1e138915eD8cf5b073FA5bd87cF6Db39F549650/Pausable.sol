// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./IPausable.sol";
import "./Governable.sol";

abstract contract Pausable is IPausable, Governable {
  bool public override paused;

  function pause(bool _paused) external override onlyGovernor {
    if (paused == _paused) revert NoChangeInPause();
    paused = _paused;
    emit PauseChange(_paused);
  }
}
