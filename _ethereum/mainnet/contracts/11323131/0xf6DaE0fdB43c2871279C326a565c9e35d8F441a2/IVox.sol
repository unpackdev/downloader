// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IVox {
  function claim(uint256 pid) external;
  function deposit(uint256 pid, uint256 amount, bool withdrawRewards) external;
  function withdraw(uint256 pid, uint256 amount, bool withdrawRewards) external;
}
