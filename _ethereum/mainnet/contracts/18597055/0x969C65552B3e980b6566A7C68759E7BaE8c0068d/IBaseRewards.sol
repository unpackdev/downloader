// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBaseRewards {
  function extraRewardsLength() external view returns (uint256);
  function extraRewards(uint256 index) external view returns(address);
  function rewardToken() external view returns(address);
  function earned(address account) external view returns(uint256);
  function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
  function withdraw(uint256 amount, bool claim) external returns(bool);
}