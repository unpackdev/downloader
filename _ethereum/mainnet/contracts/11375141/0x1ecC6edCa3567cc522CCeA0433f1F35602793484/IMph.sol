// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IMph {
  function getReward() external;
  function stake(uint256 amount) external;
  function withdraw(uint256 amount) external;
}
