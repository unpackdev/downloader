// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";


contract TreasuryLock {
  address public immutable recipient;
  address public immutable token;
  uint256 public immutable unlockDate;

  constructor(
    address recipient_,
    address token_,
    uint256 unlockDate_
  ) public {
    require(
      recipient_ != address(0),
      "TreasuryLock::constructor: can not set null recipient"
    );
    require(
      token_ != address(0),
      "TreasuryLock::constructor: can not set null token"
    );
    require(
      unlockDate_ > block.timestamp,
      "TreasuryLock::constructor: unlockDate too soon"
    );
    recipient = recipient_;
    token = token_;
    unlockDate = unlockDate_;
  }

  function claim() public {
    require(
      block.timestamp >= unlockDate,
      "TreasuryLock::claim: not ready"
    );
    uint256 balance = IERC20(token).balanceOf(address(this));
    IERC20(token).transfer(recipient, balance);
  }
}


interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address dst, uint256 rawAmount) external returns (bool);
}