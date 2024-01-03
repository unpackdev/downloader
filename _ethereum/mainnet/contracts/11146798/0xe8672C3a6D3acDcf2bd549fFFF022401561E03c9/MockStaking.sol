// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./PowerOracleStaking.sol";

contract MockStaking is PowerOracleStaking {
  constructor(address cvpToken_, address reservoir_) public PowerOracleStaking(cvpToken_, reservoir_) {}

  function mockSetTotalDeposit(uint256 totalDeposit_) external {
    totalDeposit = totalDeposit_;
  }

  event MockSlash(uint256 userId, uint256 overdueCount);

  function slash(uint256 slasherId_, uint256 overdueCount_) external override(PowerOracleStaking) {
    emit MockSlash(slasherId_, overdueCount_);
  }

  function mockSetReporter(uint256 userId_, uint256 highestDeposit_) external {
    _reporterId = userId_;
    _highestDeposit = highestDeposit_;
  }

  function mockSetUser(
    uint256 userId_,
    address adminKey_,
    address pokerKey_,
    uint256 deposit_
  ) external {
    users[userId_].adminKey = adminKey_;
    users[userId_].pokerKey = pokerKey_;
    users[userId_].deposit = deposit_;
  }

  function mockSetUserAdmin(uint256 userId_, address adminKey_) external {
    users[userId_].adminKey = adminKey_;
  }

  function mockSetUserDeposit(uint256 userId_, uint256 deposit_) external {
    users[userId_].deposit = deposit_;
  }
}
