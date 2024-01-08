// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IWETH {

  function balanceOf(address guy) external returns (uint256);

  function deposit() external payable;

  function withdraw(uint256 wad) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);

}