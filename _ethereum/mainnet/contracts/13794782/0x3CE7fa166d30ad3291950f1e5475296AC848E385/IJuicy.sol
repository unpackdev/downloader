// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IJuicy {
  function totalSupply() external view returns (uint);
  function balanceOf(address) external returns (uint256);
  function mint(address, uint) external;
  function burn(address, uint) external;
  function transferFrom(address, address, uint256) external returns (bool);
}