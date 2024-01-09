// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity 0.8.6;

import "IERC20.sol";

import "SafeOwnable.sol";

contract Vesting is SafeOwnable {

  IERC20 public asset;

  uint public startTime;
  uint public durationTime;
  uint public released;

  constructor(
    IERC20 _asset,
    uint _startTime,
    uint _durationTime
  ) {

    require(_asset != IERC20(address(0)), "Vesting: _asset is zero address");
    require(_startTime + _durationTime > block.timestamp, "Vesting: final time is before current time");
    require(_durationTime > 0, "Vesting: _duration == 0");

    asset = _asset;
    startTime = _startTime;
    durationTime = _durationTime;
  }

  function release(uint _amount) external onlyOwner {

    require(block.timestamp > startTime, "Vesting: not started yet");
    uint unreleased = releasableAmount();

    require(unreleased > 0, "Vesting: no assets are due");
    require(unreleased >= _amount, "Vesting: _amount too high");

    released += _amount;
    asset.transfer(owner, _amount);
  }

  function releasableAmount() public view returns (uint) {
    return vestedAmount() - released;
  }

  function vestedAmount() public view returns (uint) {
    uint currentBalance = asset.balanceOf(address(this));
    uint totalBalance = currentBalance + released;

    if (block.timestamp >= startTime + durationTime) {
      return totalBalance;
    } else {
      return totalBalance * (block.timestamp - startTime) / durationTime;
    }
  }
}