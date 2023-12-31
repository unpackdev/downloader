// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IPublicEndStakeable {
  function STAKE_END_DAY() external view returns(uint256);
  function STAKE_IS_ACTIVE() external view returns(bool);
  function mintHedron(uint256 stakeIndex, uint40 stakeIdParam) external;
  function endStakeHEX(uint256 stakeIndex, uint40 stakeIdParam) external;
  function getCurrentPeriod() external view returns (uint256);
}
