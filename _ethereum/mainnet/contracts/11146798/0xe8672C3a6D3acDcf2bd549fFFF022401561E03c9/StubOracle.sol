// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./PowerOracle.sol";

contract StubOracle is PowerOracle {
  constructor(
    address cvpToken_,
    address reservoir_,
    uint256 anchorPeriod_,
    TokenConfig[] memory configs_
  ) public PowerOracle(cvpToken_, reservoir_, anchorPeriod_, configs_) {}

  function stubSetUserReward(uint256 userId_, uint256 reward_) external {
    rewards[userId_] = reward_;
  }

  function stubSetPrice(bytes32 symbolHash_, uint128 value_) external {
    prices[symbolHash_] = Price(uint128(block.timestamp), value_);
  }
}
