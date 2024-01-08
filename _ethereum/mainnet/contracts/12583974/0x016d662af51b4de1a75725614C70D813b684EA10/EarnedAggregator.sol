// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./SafeMath.sol";

import "./IShare.sol";
import "./MapReducer.sol";

interface IStakingReward {
  function earned(address account) external view returns (uint256);
}

contract EarnedAggregator is IShare, MapReducer {
  constructor(address[] memory pools_) MapReducer(pools_) {}

  function balanceOf(address account) public view override(IShare) returns (uint256) {
    return reduce(account);
  }

  function sane(address stakingReward) internal view override(MapReducer) returns (bool) {
    IStakingReward(stakingReward).earned(owner());
    return true;
  }

  function map(address stakingReward, address account) internal view override(MapReducer) returns (uint256) {
    return IStakingReward(stakingReward).earned(account); 
  }
}
