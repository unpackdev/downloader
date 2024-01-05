// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./ControlledSingleRecipient.sol";

/// @title Creates a minimal proxy to the ControlledSingleRecipient prize strategy.  Very cheap to deploy.
contract ControlledSingleRecipientHarness is ControlledSingleRecipient {

  uint256 public currentTime;

  function setCurrentTime(uint256 _currentTime) external {
    currentTime = _currentTime;
  }

  function _currentTime() internal override view returns (uint256) {
    return currentTime;
  }

  function distribute() external {
    _distribute();
  }

}