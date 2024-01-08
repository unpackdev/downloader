// SPDX-License-Identifier: ISC
pragma solidity 0.7.6;

import "./IERC20.sol";

interface IStakedLyra is IERC20 {
  function stake(address to, uint256 amount) external;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;
}
