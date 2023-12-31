// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IStakedUSDe {
  function transferInRewards(uint256 amount) external;

  function rescueTokens(address token, uint256 amount, address to) external;

  function getUnvestedAmount() external view returns (uint256);

  event RewardsReceived(uint256 indexed amount, uint256 newVestingUSDeAmount);

  event LockedAmountRedistributed(address indexed from, address indexed to, uint256 amount);
}
