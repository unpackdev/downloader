// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IwETH {
  function deposit() external payable;
  function balanceOf(address) external view returns(uint256);
  function transfer(address, uint256) external returns (bool);
}
