// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IBarnbridge {
  function deposit(address staking, uint256 amount) external;
  function withdraw(address staking, uint256 amount) external;
}
