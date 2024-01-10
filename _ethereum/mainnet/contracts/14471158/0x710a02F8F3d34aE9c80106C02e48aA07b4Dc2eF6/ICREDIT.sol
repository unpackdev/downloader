// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICREDIT {
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
  function allowance(address, address) external view returns (uint256);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function burn(address, uint256) external;
}
