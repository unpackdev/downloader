// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IReservePool {
  function aprRate() external view returns (uint);
  function totalSupply() external view returns (uint);
  function totalParticipants() external view returns (uint);
  function totalRewards() external view returns (uint);
  function earned(address account) external view returns (uint rewards);
  function getTotalClaimed(address account) external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function getRewardRate(address account) external view returns (uint);
  function stake(address account, uint amount, bool isCompound) external;
  function withdraw(address account, uint amount) external;
  function claim(address account, bool compound) external;
}