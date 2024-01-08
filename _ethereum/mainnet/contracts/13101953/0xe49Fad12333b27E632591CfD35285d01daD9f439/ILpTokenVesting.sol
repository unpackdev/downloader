//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ILpTokenVesting {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function claimable(uint party) external view returns (uint);
  function claim(uint party) external returns (uint);
}
