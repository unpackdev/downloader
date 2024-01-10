// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

interface IConvexBooster {
  function deposit(
    uint256,
    uint256,
    bool
  ) external returns (bool);

  function withdraw(uint256, uint256) external returns (bool);
}
