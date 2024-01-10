// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

interface IBaseRewardPool {
  function getReward() external returns (bool);

  function balanceOf(address) external view returns (uint256);

  function withdrawAndUnwrap(uint256, bool) external returns (bool);
}
