// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract FundsLocking {
  using SafeERC20 for IERC20;

  // beneficiary of tokens to be released
  address public beneficiary;

  // timestamp of token release
  uint256 public releaseDate;

  constructor(address beneficiary_, uint256 releaseDate_) public {
    require(block.timestamp < releaseDate_, "Release date should be in the future");
    require(releaseDate_ - block.timestamp < 400 * 24 * 60 * 60, "Release date is too far");
    beneficiary = beneficiary_;
    releaseDate = releaseDate_;
  }

  /*
    Transfer locked tokens to beneficiary if time has come
  */
  function releaseFunds(IERC20 token) public {
    require(block.timestamp >= releaseDate, "Too early to release");
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0, "No tokens on the contract");
    token.safeTransfer(beneficiary, amount);
  }
}
