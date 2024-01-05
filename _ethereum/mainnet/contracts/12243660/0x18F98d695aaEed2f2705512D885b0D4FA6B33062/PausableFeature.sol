// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract PausableFeature {
  bool public paused;

  event Paused(address account);
  event Unpaused(address account);

  constructor() {
    paused = false;
  }

  function _pause() internal {
    paused = true;
    emit Paused(msg.sender);
  }

  function _unpause() internal {
    paused = false;
    emit Unpaused(msg.sender);
  }
}
