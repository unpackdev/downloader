// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

interface ILockedLiquidityEvent {
  function highestDeposit() external view returns (address, uint256);

  function startTradingTime() external view returns (uint256);

  function addLiquidity(uint256) external;

  function addLiquidityFor(address, uint256) external;
}
