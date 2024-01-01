
// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IWeth {
  function deposit() external payable;
  function approve(address guy, uint wad) external returns (bool);
}