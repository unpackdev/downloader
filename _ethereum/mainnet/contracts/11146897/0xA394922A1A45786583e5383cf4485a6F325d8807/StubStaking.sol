// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./PowerOracleStaking.sol";

contract StubStaking is PowerOracleStaking {
  constructor(address cvpToken_, address reservoir_) public PowerOracleStaking(cvpToken_, reservoir_) {}

  function stubSetTotalDeposit(uint256 totalDeposit_) external {
    totalDeposit = totalDeposit_;
  }

  function stubSetReporter(uint256 userId_, uint256 highestDeposit_) external {
    _reporterId = userId_;
    _highestDeposit = highestDeposit_;
  }

  function stubSetUser(
    uint256 userId_,
    address adminKey_,
    address pokerKey_,
    uint256 deposit_
  ) external {
    users[userId_].adminKey = adminKey_;
    users[userId_].pokerKey = pokerKey_;
    users[userId_].deposit = deposit_;
  }

  function stubSetUserDeposit(uint256 userId_, uint256 deposit_) external {
    users[userId_].deposit = deposit_;
  }
}
